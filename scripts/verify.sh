#!/usr/bin/env bash
# Show fan monitoring/control status.
echo "== hwmon devices =="
for h in /sys/class/hwmon/hwmon*; do echo "  $h: $(cat "$h/name" 2>/dev/null)"; done
echo
echo "== fan speeds (RPM) =="
grep -H . /sys/class/hwmon/hwmon*/fan*_input 2>/dev/null || echo "  (none found)"
echo
echo "== fan targets (write RPM; 0 = automatic) =="
grep -H . /sys/class/hwmon/hwmon*/fan*_target 2>/dev/null || echo "  (none found)"
echo
if command -v sensors >/dev/null; then
    echo "== sensors (fan lines) =="
    sensors 2>/dev/null | grep -i -B2 -A6 fan || true
fi
