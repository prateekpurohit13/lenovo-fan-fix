# Lenovo Yoga Pro 7 14IAH10 (83KF) — fan monitoring + control (out-of-tree modules)

These modules add, for this laptop model only:

| Module | What it does | Patch source |
|---|---|---|
| `yogafan.ko` | Reads fan RPM from the EC tachometers (`FA1S` @0x104, `FA2S` @0x137) → hwmon `fan1_input`, `fan2_input` | adds a DMI entry for 83KF with the correct ACPI paths (same fix as the pending upstream patch) |
| `lenovo-wmi-capdata.ko` | Capability-data driver, patched to **skip matches for GUIDs the firmware does not declare** | minimal out-of-tree fix, tested upstream by Navon John Lukose on this exact model |
| `lenovo-wmi-other.ko` | WMI "Other Mode" driver → hwmon `fanN_input` / `fanN_target` (target RPM; `0` = automatic) | guard for empty component match (same upstream test patch) |
| `lenovo-wmi-helpers.ko` | Shared helper symbols for the two modules above | unmodified upstream 7.2 source |

Why: mainline currently can't bind `lenovo-wmi-other` on this firmware (`WQB1` query method missing → `CAPABILITY_DATA_01` device dropped → the component master never completes), and `yogafan` has a wrong ACPI path for this model. Both fixes are pending upstream; these modules just apply them now.

## Build (no root needed)

```bash
# one-time prerequisites (versions must match the installed 'linux' package):
sudo pacman -S --needed linux-headers make

# build for the installed 'linux' kernel (auto-detected):
cd ~/lenovo-fan-fix
./build.sh
```

## Use (root)

```bash
# 1) try it manually first:
sudo ./scripts/load.sh          # add 'force' arg if fans are hidden
./scripts/verify.sh             # shows fan RPM + target files
sensors                         # optional

# 2) load on every boot:
sudo ./scripts/install.sh
sudo systemctl enable --now lenovo-fan.service
```

## Controlling fan speed

Only after the WMI modules are loaded. Ranges are enforced by the driver
(fan1: ~1500–5100, fan4: ~1800–5400 RPM on this model; values are rounded to
steps of 100; out-of-range writes fail with an error):

```bash
# find the right hwmon directory first (name: lenovo_wmi_other):
grep -H . /sys/class/hwmon/hwmon*/name

# pin both fans to (near) maximum:
echo 5100 | sudo tee /sys/class/hwmon/hwmonX/fan1_target
echo 5400 | sudo tee /sys/class/hwmon/hwmonX/fan4_target

# hand control back to the firmware:
echo 0 | sudo tee /sys/class/hwmon/hwmonX/fan1_target
echo 0 | sudo tee /sys/class/hwmon/hwmonX/fan4_target
```

While fans are pinned, the firmware curve is bypassed — don't leave a *low*
target set indefinitely and don't rely on it for safety. `0` always resets to
automatic.

## Revert / cleanup

```bash
sudo systemctl disable --now lenovo-fan.service   # unloads modules
sudo rm /etc/systemd/system/lenovo-fan.service /usr/local/sbin/lenovo-fan-*.sh
sudo rm -r /usr/local/lib/lenovo-fan
```

To unload without uninstalling: `sudo ./scripts/unload.sh`.

## Note

This is a stop-gap. Once the upstream fixes reach the Arch `linux` package
(expected for the next kernel releases), remove these modules and everything
works out of the box.

Patches used are in `patches/` for reference. Sources are upstream Linux
v7.2 (`GPL-2.0`).
