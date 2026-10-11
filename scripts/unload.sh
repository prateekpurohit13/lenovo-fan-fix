#!/usr/bin/env bash
# Remove patched modules and restore the in-tree state (run as root).
set -uo pipefail
for m in yogafan lenovo-wmi-other lenovo-wmi-capdata lenovo-wmi-helpers; do
    modprobe -r "$m" 2>/dev/null || true
done
# reload stock in-tree modules (will be present but inactive for fans)
modprobe lenovo-wmi-other 2>/dev/null || true
modprobe yogafan 2>/dev/null || true
echo ">> Unloaded patched modules, stock modules restored."
