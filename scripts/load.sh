#!/usr/bin/env bash
# Load the patched Lenovo fan modules (run as root).
# Usage: lenovo-fan-load.sh [force]
#   force = also load lenovo-wmi-other with expose_all_fans=1
set -uo pipefail
DIR="/usr/local/lib/lenovo-fan"
[[ -d "$DIR" ]] || DIR="$(cd "$(dirname "$0")/.." && pwd)/src"

# 0) Skip cleanly when the modules were built for a different kernel
#    (e.g. service fires while booted into the LTS kernel).
KERNEL_REL="$(uname -r)"
MOD_VERMAGIC="$(modinfo -F vermagic "$DIR/yogafan.ko" 2>/dev/null | awk '{print $1}')"
if [[ -n "$MOD_VERMAGIC" && "$MOD_VERMAGIC" != "$KERNEL_REL" ]]; then
    echo "Modules built for $MOD_VERMAGIC, but running kernel is $KERNEL_REL."
    echo "Skipping (rebuild with ./build.sh and reinstall to use them here)."
    exit 0
fi

# 1) Drop any stock/previous instances first (ignore if not loaded).
#    IMPORTANT: `modprobe -r` also removes now-unused dependencies
#    (e.g. firmware_attributes_class), so kernel-provided dependencies
#    must be (re)loaded AFTER this loop, not before.
for m in lenovo-wmi-other lenovo-wmi-capdata lenovo-wmi-helpers yogafan; do
    modprobe -r "$m" 2>/dev/null || true
done

# 2) Ensure stock kernel dependencies are present.
modprobe wmi || true
if ! modprobe firmware_attributes_class; then
    echo "WARNING: could not load firmware_attributes_class" >&2
fi

# 3) Load our modules.
fail=0
insmod "$DIR/lenovo-wmi-helpers.ko"     || { echo "FAILED: lenovo-wmi-helpers" >&2;  fail=1; }
insmod "$DIR/lenovo-wmi-capdata.ko"     || { echo "FAILED: lenovo-wmi-capdata" >&2;  fail=1; }
if [[ "${1:-}" == "force" ]]; then
    insmod "$DIR/lenovo-wmi-other.ko" expose_all_fans=1 \
                                        || { echo "FAILED: lenovo-wmi-other (force)" >&2; fail=1; }
else
    insmod "$DIR/lenovo-wmi-other.ko"   || { echo "FAILED: lenovo-wmi-other" >&2;      fail=1; }
fi
insmod "$DIR/yogafan.ko"                || { echo "FAILED: yogafan" >&2;             fail=1; }

sleep 1
echo ">> Loaded:"
lsmod | grep -E 'yogafan|lenovo_wmi' || true
echo
echo ">> Fan hwmon:"
for h in /sys/class/hwmon/hwmon*; do
    n="$(cat "$h/name" 2>/dev/null)" || continue
    case "$n" in yogafan|lenovo_wmi_other|lenovo-wmi-other) echo "  $h: $n";; esac
done
echo
echo ">> dmesg tail:"
dmesg 2>/dev/null | tail -12 || true
exit "$fail"
