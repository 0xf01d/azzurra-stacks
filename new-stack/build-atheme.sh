#!/usr/bin/env bash
# Build atheme-it (next-gen services) into a self-contained prefix.
#
# Environment:
#   ATHEME_REPO   git URL to clone            (default: the 0xf01d fork)
#   ATHEME_REF    commit/branch to build      (default: pinned master revision)
#   PREFIX        install prefix              (default: <repo>/install/atheme)
#   PATCH_DIR     directory holding patches   (default: <script>/patches)
#
# Requires: gcc, autoconf, automake, aclocal, pkg-config, libltdl-dev.
# The pinned atheme-it configure.ac calls AC_LANG() before AC_INIT(), which
# breaks regeneration with modern autoconf; we ship the minimal reorder as
# patches/0001-fix-configure-ac-ac-init-before-ac-lang.patch and apply it
# before regenerating configure with `aclocal -I m4` (the bundled m4 macros
# in ./m4 must be on the aclocal search path).
set -euo pipefail

ATHEME_REPO="${ATHEME_REPO:-https://github.com/0xf01d/atheme-it.git}"
ATHEME_REF="${ATHEME_REF:-88de242f4755394746444c7bd28da15127d976d2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$(cd "${HERE}/.." && pwd)/install/atheme}"
PATCH_DIR="${PATCH_DIR:-${HERE}/patches}"
SRC="${SRC:-$(mktemp -d /tmp/atheme-it-src.XXXXXX)}"

echo "==> atheme-it: ${ATHEME_REPO}@${ATHEME_REF}"
echo "==> prefix:    ${PREFIX}"
echo "==> srcdir:    ${SRC}"

git init -q "${SRC}"
git -C "${SRC}" remote add origin "${ATHEME_REPO}"
git -C "${SRC}" fetch --depth 1 origin "${ATHEME_REF}"
git -C "${SRC}" checkout --quiet FETCH_HEAD
# libmowgli-2 (core library) and modules/contrib are submodules; atheme's
# configure refuses a git checkout without them (GIT-Access.txt check) and
# recurses into libmowgli-2 via its committed configure.
git -C "${SRC}" submodule update --init --recursive --depth 1

echo "==> applying autogen-order patch"
ACFILE="${SRC}/configure.ac"
lang_line="$(grep -n '^AC_LANG' "${ACFILE}" | cut -d: -f1 | head -1 || true)"
init_line="$(grep -n '^AC_INIT' "${ACFILE}" | cut -d: -f1 | head -1 || true)"
if [ -n "${lang_line}" ] && [ -n "${init_line}" ] && [ "${lang_line}" -lt "${init_line}" ]; then
    patch -d "${SRC}" -p1 < "${PATCH_DIR}/0001-fix-configure-ac-ac-init-before-ac-lang.patch"
else
    echo "    (already ordered correctly; patch skipped)"
fi

echo "==> regenerating configure (aclocal -I m4, autoheader, autoconf)"
cd "${SRC}"
aclocal -I m4
autoheader
autoconf

echo "==> configure"
./configure \
    --prefix="${PREFIX}" \
    --disable-nls \
    --disable-contrib

echo "==> make"
make -j"$(nproc 2>/dev/null || echo 2)"

echo "==> make install"
make install

test -x "${PREFIX}/bin/atheme-services" || {
    echo "FATAL: ${PREFIX}/bin/atheme-services missing after install" >&2
    exit 1
}

echo "==> atheme-it built: $(realpath "${PREFIX}")"
