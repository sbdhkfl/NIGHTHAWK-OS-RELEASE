# NIGHTHAWK OS 1.0 — Orange Pi Zero 3 (ARM64)

A lightweight, security-focused desktop image for the **Orange Pi Zero 3**
(Allwinner H618, ARM64) built on the Armbian/Debian 13 (trixie) boot chain with
the **Kali rolling package channel** added for security tooling.

| Item | Value |
|---|---|
| Image file | `nighthawk-os-1.0-orangepi-zero3-arm64.img` (not included in this repository) |
| Image size | 1,768,947,712 bytes (1.65 GiB, **1.77 GB** — under the 2 GB target) |
| SHA256 | `126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885` |
| Format | raw disk image (flash directly, no extraction needed) |
| Architecture | ARM64 / AArch64 |
| SoC | Allwinner H618 (4x Cortex-A53) |
| Kernel | Armbian `6.18.57-current-sunxi64` (unmodified) |
| Boot chain | Armbian U-Boot/SPL (`eGON.BT0` at 8 KiB), `boot.scr` → `armbianEnv.txt` |
| Packages | 565 |
| Partition layout | MBR, partition 1 at sector 8192, ext4, label `nighthawk` |

The raw disk image is intentionally excluded from this Git repository because
it exceeds GitHub's 100 MB file limit. `SHA256SUMS` records the expected
checksum for the image described here; the image must be obtained separately
or rebuilt using the included build scripts.

## What is included

- **Desktop:** XFCE4 (session, panel, settings, Thunar, terminal, appfinder,
  power manager, screenshooter, clipman) — minimal, no recommended extras.
- **Display manager:** LightDM + GTK greeter, NIGHTHAWK wallpaper/theme.
- **Networking:** NetworkManager + `nm-applet` tray + `nmtui`; systemd-networkd
  and the standalone wpa_supplicant unit are disabled.
- **Browser:** Firefox ESR 153 with NIGHTHAWK policies and system prefs.
- **Security toolkit:** nmap, lynis, tcpdump, ufw, dnsutils, openssh
  (server+client), git, python3 + venv, curl, wget.
- **Branding:** crimson/dark wallpaper and logo, GTK2/GTK3 theme, icon theme,
  terminal palette, MOTD banner, `nighthawk` helper command.
- **Memory tuning:** sysctl profile + zram swap (`ram/4`) via
  `armbian-zram-config`, tuned for the 2 GB board (works unchanged on 4 GB).
- **First boot:** interactive Armbian setup wizard (create user, set passwords).

## Package sources

```
Debian trixie / trixie-updates / trixie-backports / trixie-security   priority 990
Armbian (board support, kernel, u-boot)                              priority 990
Kali rolling (http.kali.org, arm64)                                  priority 500
```

The Debian base is deliberately kept at a higher pin priority so core
libraries stay ABI-stable; Kali packages are used for security tooling and can
be pulled explicitly with `apt-get install -t kali-rolling <pkg>`.

## Quick start

1. Write the image to a microSD card (8 GB or larger) — see `FLASHING.md`.
2. Insert the card, connect HDMI + USB keyboard, power on with a 5 V/3 A supply.
3. The first boot resizes the root filesystem to the card and then opens the
   NIGHTHAWK setup wizard on the console: create your user and set passwords.
4. Log in at the LightDM greeter and use `nmtui` or the tray applet to join Wi-Fi.

Full details: `FLASHING.md`, `HARDWARE-COMPATIBILITY.md`, `TROUBLESHOOTING.md`,
and `BUILD-REPORT.md` (how it was built and exactly what was verified).

## Default security posture

- No pre-configured user account and no auto-join Wi-Fi credentials.
- The console starts the Armbian first-login wizard as root; the wizard forces
  a new root password and creation of a normal user before the desktop is used.
- SSH: `PermitRootLogin no`, `PasswordAuthentication no` (key-based only).
  SSH host keys are regenerated on first boot, so nothing is shared between
  flashed cards.
- UFW is installed but **not enabled**; enable it after you can log in:
  `sudo ufw allow ssh && sudo ufw enable`.
