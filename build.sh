#!/usr/bin/env bash
# Build the patched modules for the installed 'linux' kernel.
# Requires: linux-headers (matching version), make, gcc.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

KVER="${1:-}"
if [[ -z "$KVER" ]]; then
    pkgver="$(pacman -Q linux | awk '{print $2}')"   # e.g. 7.2.9.arch1-1
    KVER="${pkgver/.arch/-arch}"                      # e.g. 7.2.9-arch1-1
fi
KDIR="/lib/modules/${KVER}/build"
if [[ ! -d "$KDIR" ]]; then
    echo "ERROR: $KDIR not found." >&2
    echo "Install the matching headers, e.g.:  sudo pacman -S --needed linux-headers make" >&2
    exit 1
fi
echo ">> Building for kernel: $KVER"
make -C "$KDIR" M="$DIR/src" modules -j"$(nproc)"
echo
echo ">> Modules built:"
ls -1 "$DIR/src"/*.ko
