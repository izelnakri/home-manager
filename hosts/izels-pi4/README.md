# pi4-nas (Raspberry Pi 4 Model B 8GB)

NixOS 26.05, mainline kernel 7.3.5 + mainline DTB, U-Boot → extlinux, cross-built on x86_64.
Verified on the real Pi: boot, HDMI console + Hyprland, Wi-Fi + internet, Bluetooth (BCM4345C0),
sshd, sudo, NetworkManager without sudo, root expanded to the full card.

Login: `izelnakri` / `testing` (temporary — change with `passwd`). Root has the same password.

## Images

| Image | Root FS | Status |
|---|---|---|
| `make pi4-image` → `result-pi4-nas` | ext4 (default) | verified on the real Pi |
| `make pi4-image-btrfs` → `result-pi4-nas-btrfs` | btrfs, zstd | verified in QEMU (all files root-owned, resize, services, Wi-Fi) |

Flash (card must be removable + unmounted; ~3 min):

```sh
sudo make pi4-flash DEV=/dev/sdc               # ext4
sudo make pi4-flash DEV=/dev/sdc ROOTFS=btrfs  # btrfs
lsblk -o NAME,LABEL,FSTYPE /dev/sdc            # NIXOS_SD shows ext4 / btrfs
```

If you run the btrfs card, set `pi4.rootFs = "btrfs";` in `configuration.nix` before any
`make pi4-deploy` (deploys must match the card's root filesystem).

## On the Pi

- First boot: ~1–2 min (root resize + Nix store registration), then `pi4-nas login:` on HDMI.
- Logging in on tty1 starts Hyprland (`/etc/hypr/hyprland.lua`, ported from
  `static/.config/hypr/hyprland.lua`; `~/.config/hypr/hyprland.lua` overrides it).
  SUPER+Return/Q = foot, SUPER+R = nmtui, SUPER+M = exit. `NO_HYPRLAND=1` or Ctrl+Alt+F2 = text console.
- Wi-Fi: `nmtui` or `nmcli dev wifi connect "<SSID>" --ask` (no sudo needed).
- Bluetooth: `bluetoothctl` → `power on`, `scan on`.
- Diagnostics: 2 min after boot `/boot/pi4-diagnostics.txt` (FAT, readable from any card reader:
  nmcli, ip, dmesg, NetworkManager/Bluetooth journal, Hyprland log).

## Stable SSH address (Tailscale)

Once, on the Pi: `sudo tailscale up --hostname=izels-pi4` and open the printed URL.
Then from any tailnet device: `ssh izelnakri@izels-pi4`. On the LAN without Tailscale:
`ssh izelnakri@pi4-nas.lan` (router DNS; mDNS `.local` is blocked on campus Wi-Fi).
FOSS control server later: Headscale (same client, `--login-server`).

## Fast feedback loop (native, minutes)

```sh
make pi4-deploy                                  # nixinate: cross-build here, switch on the Pi
make run-pi4 ARGS="--ssh izels-pi4"              # ~22 checks in seconds (or --ssh pi4-nas.lan)
```

## Pre-flash verification (QEMU, no hardware)

```sh
make pi4-check                    # static image checks, seconds
make run-pi4                      # raspi4b (real U-Boot path) + virt (A72x4/8G) system checks
make run-pi4 ARGS="--tier uboot"  # U-Boot → extlinux → kernel only, ~1 min
make pi4-vm                       # interactive serial console
```

Fails fast on the first FAIL (`--keep-going` for a full report). The virt VM runs its check
groups (Wi-Fi via mac80211_hwsim, Bluetooth, diagnostics, Hyprland via virtual keyboard +
screenshot, serial login + sudo) concurrently. First boot under emulation is slow (~7 min to
sshd), so use it for image/boot-chain changes and the native loop for config changes.

## Meta Quest 3 (Limbo, emulated)

Bundle: `~/pi4-nas-limbo/` (also pushed to the headset at `/sdcard/Download/pi4-nas-limbo/`):
`nixos-pi4-nas-btrfs.qcow2` (64G virtual), `Image`, `initrd`, `cmdline.txt`, `SHA256SUMS`.
Limbo VM: ARM64, machine `virt`, CPU `cortex-a72`, 4 cores, 3072 MB, kernel `Image`,
initrd `initrd`, kernel cmdline = contents of `cmdline.txt`, disk = the qcow2 (virtio),
user networking. First boot takes long under emulation (device timeout is set to 30 min).

## Root causes fixed (see git log for details)

- U-Boot: bootable flag on the btrfs partition; `bootcmd` only listed bootflows.
- nixpkgs `make-btrfs-fs.nix`: image files owned by the build user → systemd tmpfiles and
  NetworkManager's Wi-Fi plugin refused them. Fixed builder runs mkfs under `unshare -r`.
- NetworkManager needs `networking.wireless` in D-Bus mode (don't force it off).
- `console=ttyAMA0` occupied the Bluetooth UART. Hyprland 0.57 parses configs as Lua.
- Pi 4 has two DRM cards (v3d render-only, vc4 HDMI): the launcher picks the one with connectors.
