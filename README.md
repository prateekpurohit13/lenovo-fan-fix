# Lenovo Yoga Pro 7 14IAH10 (83KF) — fan RPM monitoring + fan speed control

Out-of-tree kernel modules that make the **two physical fans** of this laptop
visible and controllable on Linux, for the current firmware/kernels where
mainline does not fully work yet.

Verified on: Lenovo Yoga Pro 7 14IAH10, BIOS QGCN36WW, `linux` 7.2.9-arch1-1
(Arch). The fans are exposed through two interfaces:

| Interface | Attributes | What it is |
|---|---|---|
| `yogafan` (hwmon) | `fan1_input`, `fan2_input` (smoothed) | EC tachometers `FA1S` (0x104) / `FA2S` (0x137) |
| `lenovo_wmi_other` (hwmon) | `fan1_input/target`, `fan4_input/target` | Same two fans via Lenovo WMI fan IDs **1** and **4** — IDs are sparse, the machine has **2 fans, not 4** |

Verified mapping: WMI `fan1` ↔ EC `fan1` (one physical fan),
WMI `fan4` ↔ EC `fan2` (the other). Pinning one target spins only that fan.

## Why these modules exist

Mainline currently doesn't work on this machine:

- `yogafan` has a DMI entry for 83KF but with a wrong ACPI path
  (`...EC0.FANS` doesn't exist here; the tachometers are `FA1S`/`FA2S`),
  so it returns `-ENODEV` and no RPM shows up.
- `lenovo-wmi-other` never completes its component-master bind, because the
  firmware drops the `CAPABILITY_DATA_01` WMI block (its `WQB1` query method
  is missing), so a required component is never provided.
- The legacy `ideapad_laptop` `fan_mode` interface exists but is ignored by
  this EC firmware (writes have no effect).

The modules here apply the (pending) upstream fixes locally. Remove everything
once those fixes land in the Arch kernel (~7.4+).

## Build

```bash
# prerequisites (must match the installed linux kernel)
sudo pacman -S --needed linux-headers make

./build.sh
```

## Install and load

```bash
sudo ./scripts/install.sh                 # copies modules + systemd unit
sudo systemctl enable --now lenovo-fan.service
./scripts/verify.sh                       # shows hwmon devices + fan values
```

`load.sh` skips cleanly when the modules were built for a different kernel
(e.g. booted into `linux-lts`) — fan support cannot exist there.

## Usage

Read fan speeds (smoothed EC tachs + instant WMI values):

```bash
sensors
```

Control fan speed (root; values = target RPM, multiples of 100; `0` = automatic):

```bash
# locate the WMI hwmon (the one exposing fanN_target)
grep -H . /sys/class/hwmon/hwmon*/name

echo 4000 | sudo tee /sys/class/hwmon/hwmonX/fan1_target   # pin physical fan 1
echo 0    | sudo tee /sys/class/hwmon/hwmonX/fan1_target   # release to firmware curve

echo 5400 | sudo tee /sys/class/hwmon/hwmonX/fan4_target   # pin physical fan 2
echo 0    | sudo tee /sys/class/hwmon/hwmonX/fan4_target   # release
```

Limits (enforced by the driver; out-of-range writes return an error):
`fan1`: 1500–5100 RPM · `fan4`: 1800–5400 RPM

While a fan is pinned, the firmware curve is bypassed for it. Don't leave a
*low* target set — use `0` to hand control back.

## Boot notes

- The modules are built for the **`linux` (7.2.x)** kernel — boot that entry.
- This machine's boot menu is UKI-based: the two identically named
  "Arch Linux" entries are `/boot/EFI/Linux/arch-linux.efi` (7.2.x) and
  `arch-linux-lts.efi`. With `GRUB_DEFAULT=1`, the 7.2.x UKI boots by default.
- `linux-lts` remains installed as a fallback; the service skips silently there.

## Maintenance

After every kernel update:

```bash
./build.sh && sudo ./scripts/install.sh && sudo systemctl restart lenovo-fan.service
```

Remove (once upstream fixes land):

```bash
sudo systemctl disable --now lenovo-fan.service
sudo rm /etc/systemd/system/lenovo-fan.service /usr/local/sbin/lenovo-fan-*.sh
sudo rm -r /usr/local/lib/lenovo-fan
```

## Layout

- `src/` — patched upstream v7.2 sources + `Makefile` (out-of-tree build)
- `scripts/` — `load.sh`, `unload.sh`, `verify.sh`, `install.sh`, systemd unit
- `patches/` — reference diffs + pristine upstream copies
- `build.sh` — builds against the installed `linux` kernel

## Upstream references

- yogafan path fix for 83KF: https://patchew.org/linux/20260913214713.205208-1-navonjohnlukose@gmail.com/
- lenovo-wmi robustness series (bind fix): https://patchew.org/linux/20261009-lwmi-wmi-new-api-v2-0-402828382679@rong.moe/
- Upstream test on this model, `fanX_target` pinning: https://lkml.iu.edu/2609.3/06460.html
