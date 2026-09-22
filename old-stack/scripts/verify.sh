#!/bin/sh
# Old-stack verification: proves the bahamut + azzurra-services pipeline end
# to end, one level deeper than the upstream testnet smoke (which is
# deliberately shallow and defers exactly these checks to CI):
#
#   1. ChanServ answers a PRIVMSG — client → hub → services link →
#      pseudo-client → back through the link. The whole data path.
#   2. An oper's /map shows hub + leaf4 + leaf6 — the 3-ircd link really
#      happened, not just a hub talking to itself.
#   3. A whois issued on the hub sees a user connected to leaf-v4 — S2S
#      carries users, not only server stamps.
#   4. NickServ REGISTER + IDENTIFY lands +r (RPL_WHOISREGNICK 307) on a
#      leaf user — services → SVSMODE → leaf U:line, the exact privileged
#      path that silently breaks when a leaf is missing its U: line.
#   5. A channel message sent on the hub arrives on leaf-v4 — full channel
#      data path across the S2S link (JOIN + PRIVMSG both directions).
#
# Exit non-zero (with compose logs) on the first failed assertion.
set -u
cd "$(dirname "$0")/.."

# Source build: the ghcr.io/azzurra/* packages are private (anonymous pull
# rejected), so CI — and any machine without a package-granted GHCR login —
# builds both images from the pinned upstream refs in compose.yaml.
COMPOSE_FILES="-f compose.yaml"
HUB_NET=old-stack_svc-net
LEAF4_NET=old-stack_leaf4-net
DEADLINE_SECONDS=240

dump_and_die() {
    echo "=== FAILED: $1 ==="
    docker compose $COMPOSE_FILES ps || true
    docker compose $COMPOSE_FILES logs --tail=160 hub leaf-v4 leaf-v6 services || true
    exit 1
}

# probe <network> <host> <port> <irc-script> — run a scripted session in a
# throwaway alpine container on the compose network. Probes run in-network:
# from the published host port bahamut's reverse-DNS stalls on absent PTR
# records, in-network docker DNS answers and registration completes.
probe() {
    _net=$1; _host=$2; _port=$3; _script=$4
    docker run --rm --network "$_net" alpine:3.20 sh -c "
        apk add --no-cache netcat-openbsd >/dev/null 2>&1
        ( $_script ) | nc -w 45 $_host $_port
    " 2>/dev/null || true
}

echo "=== bringing old stack up (detached, source build, pinned refs) ==="
docker compose $COMPOSE_FILES up -d --build --wait || dump_and_die "compose up"

# --- 1. ChanServ round-trip: services link is alive --------------------------
echo "=== [1/5] ChanServ answers (services link alive) ==="
deadline=$(( $(date +%s) + DEADLINE_SECONDS ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    out=$(probe "$HUB_NET" hub.azzurra.chat 6667 '
        printf "NICK smoke\r\nUSER smoke 0 * :smoke\r\n"; sleep 3;
        printf "PRIVMSG ChanServ :HELP\r\n"; sleep 4;
        printf "QUIT\r\n"; sleep 1
    ')
    if printf '%s\n' "$out" | grep -qE '^:ChanServ![^ ]+ (NOTICE|PRIVMSG) smoke '; then
        echo "=== ChanServ replied ==="
        break
    fi
    sleep 5
    [ "$(date +%s)" -lt "$deadline" ] || dump_and_die "no ChanServ reply within ${DEADLINE_SECONDS}s"
done

# --- 2. /links shows the three linked ircd + the U-lined services ------------
echo "=== [2/5] /links shows hub + leaf4 + leaf6 + services ==="
# bahamut-azzurra has no MAP command (421 Unknown command); LINKS as oper
# lists every linked server, services included (U-lined servers are hidden
# from non-opers only).
deadline=$(( $(date +%s) + DEADLINE_SECONDS ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    out=$(probe "$HUB_NET" hub.azzurra.chat 6667 '
        printf "NICK mapper\r\nUSER mapper 0 * :mapper\r\n"; sleep 3;
        printf "OPER testoper testoperpass\r\n"; sleep 2;
        printf "LINKS\r\n"; sleep 3;
        printf "QUIT\r\n"; sleep 1
    ')
    if printf '%s\n' "$out" | grep -q "leaf4.azzurra.chat" \
       && printf '%s\n' "$out" | grep -q "leaf6.azzurra.chat" \
       && printf '%s\n' "$out" | grep -q "hub.azzurra.chat" \
       && printf '%s\n' "$out" | grep -q "services.azzurra.chat"; then
        echo "=== /links shows all four servers ==="
        break
    fi
    sleep 5
    [ "$(date +%s)" -lt "$deadline" ] || dump_and_die "links never showed hub+leaf4+leaf6+services"
done

# --- 3. cross-leaf whois: hub sees a leaf-v4 user ----------------------------
echo "=== [3/5] hub-side whois sees a leaf-v4 user ==="
# One long-lived bravo session on leaf4 (the whois target), alpha on the hub.
( probe "$LEAF4_NET" leaf4.azzurra.chat 6667 '
    printf "NICK bravo\r\nUSER bravo 0 * :bravo\r\n"; sleep 15
' ) &
bravo_pid=$!
trap 'kill "$bravo_pid" 2>/dev/null || true' EXIT
deadline=$(( $(date +%s) + DEADLINE_SECONDS ))
linked=0
while [ "$(date +%s)" -lt "$deadline" ]; do
    out=$(probe "$HUB_NET" hub.azzurra.chat 6667 '
        printf "NICK alpha\r\nUSER alpha 0 * :alpha\r\n"; sleep 3;
        printf "WHOIS bravo\r\n"; sleep 3;
        printf "QUIT\r\n"; sleep 1
    ')
    # RPL_WHOISUSER (311) for bravo: the user crossed the S2S link.
    if printf '%s\n' "$out" | grep -qE ' 311 [^ ]+ bravo '; then
        echo "=== whois 311 bravo crossed the link ==="
        linked=1
        break
    fi
    sleep 5
done
[ "$linked" -eq 1 ] || dump_and_die "hub-side WHOIS never saw leaf-v4 user bravo"

# --- 4. NickServ REGISTER/IDENTIFY lands +r via SVSMODE ----------------------
echo "=== [4/5] NickServ register + identify => 307 on leaf user ==="
deadline=$(( $(date +%s) + DEADLINE_SECONDS ))
registered=0
while [ "$(date +%s)" -lt "$deadline" ]; do
    out=$(probe "$LEAF4_NET" leaf4.azzurra.chat 6667 '
        printf "NICK carol\r\nUSER carol 0 * :carol\r\n"; sleep 4;
        printf "PRIVMSG NickServ :REGISTER carolpass carol@example.com\r\n"; sleep 5;
        printf "PRIVMSG NickServ :IDENTIFY carolpass\r\n"; sleep 5;
        printf "WHOIS carol\r\n"; sleep 3;
        printf "QUIT\r\n"; sleep 1
    ')
    # Identify must have succeeded...
    if printf '%s\n' "$out" | grep -qE '^:NickServ![^ ]+ NOTICE carol :.*(Password accepted|identified)'; then
        # ...and the +r umode must have crossed services -> hub -> leaf
        # (RPL_WHOISREGNICK 307). This is the assertion that fails when a
        # leaf lacks its U: line.
        if printf '%s\n' "$out" | grep -qE ' 307 carol carol '; then
            echo "=== 307 RPL_WHOISREGNICK landed on the leaf ==="
            registered=1
            break
        fi
    fi
    sleep 5
done
[ "$registered" -eq 1 ] || dump_and_die "NickServ register/identify never produced 307 on the leaf"

# --- 5. channel data path: hub PRIVMSG reaches a leaf-v4 channel client ------
echo "=== [5/5] channel message crosses hub -> leaf-v4 ==="
# carol-2 sits in #verify on leaf4; delta joins the same channel from the hub
# and speaks. The message must arrive on the leaf — the full channel
# broadcast path across the S2S link. carol-2's transcript is captured to a
# file: a backgrounded command substitution cannot hand its variable back to
# this shell.
deadline=$(( $(date +%s) + DEADLINE_SECONDS ))
chan_ok=0
leaf_log=$(mktemp)
while [ "$(date +%s)" -lt "$deadline" ]; do
    probe "$LEAF4_NET" leaf4.azzurra.chat 6667 '
        printf "NICK carol2\r\nUSER carol2 0 * :carol2\r\n"; sleep 4;
        printf "JOIN #verify\r\n"; sleep 26;
        printf "QUIT\r\n"; sleep 1
    ' > "$leaf_log" 2>/dev/null &
    leaf_pid=$!
    probe "$HUB_NET" hub.azzurra.chat 6667 '
        printf "NICK delta\r\nUSER delta 0 * :delta\r\n"; sleep 6;
        printf "JOIN #verify\r\n"; sleep 4;
        printf "PRIVMSG #verify :cross-leaf hello\r\n"; sleep 4;
        printf "QUIT\r\n"; sleep 1
    ' >/dev/null 2>&1 || true
    wait "$leaf_pid" 2>/dev/null || true
    # carol2 must have seen delta speak in #verify.
    if grep -qE '^:delta![^ ]+ PRIVMSG #verify ' "$leaf_log"; then
        echo "=== cross-leaf channel message arrived on leaf-v4 ==="
        chan_ok=1
        break
    fi
    sleep 5
done
rm -f "$leaf_log"
[ "$chan_ok" -eq 1 ] || dump_and_die "channel message never crossed hub -> leaf-v4"

echo "=== ALL OLD-STACK CHECKS GREEN ==="
