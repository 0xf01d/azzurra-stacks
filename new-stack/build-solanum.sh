#!/usr/bin/env bash
# Build solanum-it (next-gen IRCd) into a self-contained prefix.
#
# Environment:
#   SOLANUM_REPO  git URL to clone            (default: the 0xf01d fork)
#   SOLANUM_REF   commit/branch to build      (default: pinned main revision)
#   PREFIX        install prefix              (default: <repo>/install/solanum)
#
# Requires: gcc, meson >= 0.62, ninja, bison, flex, pkg-config,
#           libsqlite3-dev, libssl-dev (TLS backend, auto-detected).
set -euo pipefail

SOLANUM_REPO="${SOLANUM_REPO:-https://github.com/0xf01d/solanum-it.git}"
SOLANUM_REF="${SOLANUM_REF:-96b2cfa1a13a8ad30a6dd85af540cd0f6f74a621}"
PREFIX="${PREFIX:-$(cd "$(dirname "$0")/.." && pwd)/install/solanum}"
SRC="${SRC:-$(mktemp -d /tmp/solanum-it-src.XXXXXX)}"

echo "==> solanum-it: ${SOLANUM_REPO}@${SOLANUM_REF}"
echo "==> prefix:     ${PREFIX}"
echo "==> srcdir:     ${SRC}"

git init -q "${SRC}"
git -C "${SRC}" remote add origin "${SOLANUM_REPO}"
# GitHub serves arbitrary commit SHAs for shallow fetches.
git -C "${SRC}" fetch --depth 1 origin "${SOLANUM_REF}"
git -C "${SRC}" checkout --quiet FETCH_HEAD

echo "==> meson setup"
meson setup "${SRC}/build" "${SRC}" \
    -Dprefix="${PREFIX}" \
    -Dbuildtype=release

echo "==> ninja"
ninja -C "${SRC}/build"

echo "==> meson install"
meson install -C "${SRC}/build"

test -x "${PREFIX}/bin/solanum" || {
    echo "FATAL: ${PREFIX}/bin/solanum missing after install" >&2
    exit 1
}

# The services smoke generates its ircd.conf from the testsuite template;
# meson does not install testsuite/, so keep the template beside the prefix.
install -Dm644 "${SRC}/testsuite/ircd.conf.1" \
    "${PREFIX}/share/testsuite/ircd.conf.1"

echo "==> solanum-it built: $(realpath "${PREFIX}")"
