#!/usr/bin/env bash
# Install built modules + systemd service (run as root, after ./build.sh).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
[[ $(id -u) -eq 0 ]] || { echo "Run with sudo."; exit 1; }
[[ -f "$DIR/src/yogafan.ko" ]] || { echo "No .ko files — run ./build.sh first."; exit 1; }

install -d /usr/local/lib/lenovo-fan
install -m 0644 "$DIR"/src/*.ko /usr/local/lib/lenovo-fan/
install -m 0755 "$DIR/scripts/load.sh"   /usr/local/sbin/lenovo-fan-load.sh
install -m 0755 "$DIR/scripts/unload.sh" /usr/local/sbin/lenovo-fan-unload.sh
install -m 0644 "$DIR/scripts/lenovo-fan.service" /etc/systemd/system/lenovo-fan.service
systemctl daemon-reload
echo ">> Installed. Enable + load now with:"
echo "   sudo systemctl enable --now lenovo-fan.service"
