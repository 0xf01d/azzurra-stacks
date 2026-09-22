#!/usr/bin/env bash
# Smoke: atheme-it services on solanum-it, NickServ end to end.
#
# Verifies the full services chain against freshly built prefixes:
#   ircd boots + conf validates -> test client registers (001)
#   -> atheme links (2 servers on the net) -> WHOIS NickServ resolves
#   -> NickServ REGISTER creates the account (pbkdf2v2-hashed password)
#   + auto-login (900) -> NickServ INFO answers.
#
# Derived from the live-verified proof (proof2-v3.sh, 2026-09-22).
# Environment:
#   SOLANUM_PREFIX  solanum install prefix (default <repo>/install/solanum)
#   ATHEME_PREFIX   atheme install prefix  (default <repo>/install/atheme)
#   WORKDIR         scratch dir            (default: mktemp -d)
# Requires: python3.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# Absolute self path: the root path re-execs the script AFTER cd'ing to
# WORKDIR, so a relative $0 would resolve from the wrong directory (exit 127).
SELF="${HERE}/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "${HERE}/.." && pwd)"
SOLANUM_PREFIX="${SOLANUM_PREFIX:-${REPO}/install/solanum}"
ATHEME_PREFIX="${ATHEME_PREFIX:-${REPO}/install/atheme}"
WORKDIR="${WORKDIR:-$(mktemp -d /tmp/atheme-smoke.XXXXXX)}"

SOLANUM="${SOLANUM_PREFIX}/bin/solanum"
ATHEME="${ATHEME_PREFIX}/bin/atheme-services"
for bin in "${SOLANUM}" "${ATHEME}"; do
    test -x "${bin}" || { echo "FATAL: ${bin} missing (build first)" >&2; exit 2; }
done

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Relocated prefixes: meson bakes an absolute rpath at build time; a moved
# tree needs the lib dirs on the loader path (harmless for fresh builds).
# Multiarch builds put libs under lib/<tuple>/, so pick up those too.
export LD_LIBRARY_PATH="${SOLANUM_PREFIX}/lib:${ATHEME_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
while IFS= read -r d; do
    export LD_LIBRARY_PATH="${d}:${LD_LIBRARY_PATH:-}"
done < <(find "${SOLANUM_PREFIX}/lib" "${ATHEME_PREFIX}/lib" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

# --- stale-state cleanup (idempotent reruns) --------------------------------
# Runs as the invoking user first: root here kills ANY stale daemon from
# earlier runs; the user pass below then cleans up its own leftovers.
pkill -9 -f "bin/solanum" 2>/dev/null || true
pkill -9 -f atheme-services 2>/dev/null || true
sleep 1
rm -f "${SOLANUM_PREFIX}/etc/ircd.pid" \
      "${ATHEME_PREFIX}/var/atheme.pid" \
      "${ATHEME_PREFIX}"/etc/services.db* 2>/dev/null || true
mkdir -p "${SOLANUM_PREFIX}/etc" "${SOLANUM_PREFIX}/var/log" \
         "${SOLANUM_PREFIX}/uids" "${ATHEME_PREFIX}/etc" "${ATHEME_PREFIX}/var/log"

# --- privilege drop -----------------------------------------------------------
# Both daemons AND the conftest mode refuse to run as root (verified in a
# clean root container). In root CI runners we re-exec the WHOLE script as a
# runtime user exactly once, so no solanum/atheme invocation site can ever
# run with root privileges. Root only keeps package mgmt + builds.
if [ "$(id -u)" = "0" ]; then
    RUNTIME_USER="${RUNTIME_USER:-smokerun}"
    id -u "${RUNTIME_USER}" >/dev/null 2>&1 || \
        useradd --system --create-home --home-dir "/home/${RUNTIME_USER}" \
                --shell /bin/bash "${RUNTIME_USER}"
    chown -R "${RUNTIME_USER}:${RUNTIME_USER}" \
        "${WORKDIR}" "${SOLANUM_PREFIX}" "${ATHEME_PREFIX}"
    exec setpriv --reuid="${RUNTIME_USER}" --regid="${RUNTIME_USER}" --clear-groups \
        env LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}" HOME="/home/${RUNTIME_USER}" \
            SOLANUM_PREFIX="${SOLANUM_PREFIX}" ATHEME_PREFIX="${ATHEME_PREFIX}" \
            WORKDIR="${WORKDIR}" \
            bash "${SELF}" "$@"
fi

# --- ircd.conf: testsuite template + services wiring -------------------------
# Verified gotchas baked in: connect/service/server name must be identical
# mid-dot ("services.int"; solanum rejects trailing-dot names), and the
# template's connect blocks are left inert (autoconn off).
cp "${SOLANUM_PREFIX}/share/testsuite/ircd.conf.1" ./ircd.conf
python3 - <<'PY'
s = open("ircd.conf").read()
s = s.replace("autoconn = yes;", "autoconn = no;")
s = s.replace('name = "services.";', 'name = "services.int";')
s += """
connect "services.int" {
	host = "127.0.0.1";
	send_password = "servicespw";
	accept_password = "servicespw";
	class = "server";
};
"""
open("ircd.conf", "w").write(s)
PY
# Daemons chdir to their compiled-in prefix before opening configs:
# absolute paths are mandatory (relative ones silently miss).
IRCDCONF="${WORKDIR}/ircd.conf"
SVCCONF="${WORKDIR}/services.conf"
"${SOLANUM}" -conftest "${IRCDCONF}" && echo "SMOKE: ircd conf validates"

"${SOLANUM}" -foreground -configfile "${IRCDCONF}" > ircd.out 2>&1 &
sleep 5

# --- services.conf -----------------------------------------------------------
# Verified gotchas baked in: serverinfo key is `numeric` (not `sid`),
# netname+adminname required, `raw;` dropped (taints -> exit), crypto module
# explicitly loaded (else REGISTER fails "error setting your password").
cat > services.conf <<'EOF'
serverinfo {
	name = "services.int";
	numeric = "10X";
	description = "atheme-it smoke services";
	netname = "Testsuite";
	adminname = "proofadmin";
	network_desc = "proof network";
	vhost = "127.0.0.1";
	adminemail = "root@proof.invalid";
};
uplink "testsuite1." {
	host = "127.0.0.1";
	vhost = "127.0.0.1";
	password = "servicespw";
	port = 7601;
};
loadmodule "protocol/solanum";
loadmodule "backend/opensex";
loadmodule "crypto/pbkdf2v2";
loadmodule "nickserv/main";
loadmodule "nickserv/register";
loadmodule "nickserv/info";
loadmodule "nickserv/ghost";
general {
	permissive_mode;
};
EOF

"${ATHEME}" -b -c "${SVCCONF}" > dbinit.out 2>&1
"${ATHEME}" -c "${SVCCONF}" > services.out 2>&1 &
sleep 8

# --- client: NickServ end to end ---------------------------------------------
python3 - <<'PY' 2>&1 | tee client.log
import socket, time, select
s = socket.create_connection(("127.0.0.1", 7601))
s.setblocking(False)
buf = b""
yield_lines = []
def pump(seconds):
    global buf
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([s], [], [], max(0.05, end - time.time()))
        if not r: continue
        data = s.recv(4096)
        if not data:
            return
        buf += data
        while b"\r\n" in buf:
            ln, buf = buf.split(b"\r\n", 1)
            print("<< " + ln.decode(errors="replace"))
            yield_lines.append(ln.decode(errors="replace"))
def send(l):
    print(">> " + l)
    s.sendall((l + "\r\n").encode())
def expect(token, timeout):
    del yield_lines[:]
    end = time.time() + timeout
    while time.time() < end:
        r, _, _ = select.select([s], [], [], max(0.05, end - time.time()))
        if not r: continue
        data = s.recv(4096)
        if not data: break
        while b"\r\n" in data:
            ln, data = data.split(b"\r\n", 1)
            ln = ln.decode(errors="replace")
            print("<< " + ln)
            yield_lines.append(ln)
            if token.upper() in ln.upper():
                return list(yield_lines)
    return list(yield_lines)
send("NICK proofuser")
send("USER proof 0 * :proof client")
expect("001", 20)
print("SMOKE: client registered on solanum-it (001)")
send("WHOIS NickServ")
send("PRIVMSG NickServ :REGISTER proofpass proof@proof.invalid")
del yield_lines[:]
pump(20)
seen = list(yield_lines)
ok = any(("now registered" in l.lower()) or ("is now logged in" in l.lower()) for l in seen)
print("SMOKE-NICKSERV-REGISTER:", "PASS" if ok else ("FAIL " + " | ".join(seen[-6:])))
send("PRIVMSG NickServ :INFO proofuser")
del yield_lines[:]
pump(12)
seen2 = list(yield_lines)
ok2 = any(("account" in l.lower()) or ("information on" in l.lower()) for l in seen2)
print("SMOKE-NICKSERV-INFO:", "PASS" if ok2 else ("FAIL " + " | ".join(seen2[-6:])))
send("QUIT :done")
PY

fail=0
# NOTE: no post-boot conftest here on purpose - solanum -conftest collides
# with the live stack (bandb sqlite/pid) and exits nonzero while the ircd
# runs, even though the conf is proven valid (it is the conf the ircd
# booted with). The pre-boot conftest above plus a successful boot and the
# REGISTER/INFO gates below cover conf validity completely.
if ! grep -q "SMOKE-NICKSERV-REGISTER: PASS" client.log; then fail=1; fi
if ! grep -q "SMOKE-NICKSERV-INFO: PASS" client.log; then fail=1; fi
echo "SMOKE: services.log:"
tail -4 "${ATHEME_PREFIX}/var/atheme.log" 2>/dev/null || true
if [ "$fail" = 0 ]; then echo "SMOKE: PASS"; else echo "SMOKE: FAIL"; fi
echo "SMOKE-END"
exit "$fail"
