# NIGHTHAWK OS — Platform Releases

This repository contains downloadable NIGHTHAWK OS images for two separate hardware families. Choose the correct image for your device.

A lightweight, security-focused desktop image for the **Orange Pi Zero 3**
(Allwinner H618, ARM64) built on the Armbian/Debian 13 (trixie) boot chain with
the **Kali rolling package channel** added for security tooling.

> **Recommended hardware revision:** Use the **Orange Pi Zero 3 R2**. The R1 board revision has limited/unreliable Wi-Fi support with NIGHTHAWK OS, while R2 provides better Wi-Fi support. If built-in Wi-Fi matters, choose R2 rather than R1.

| Item | Value |
|---|---|
| Image file after extraction | `nighthawk-os-1.0-orangepi-zero3-arm64.img` |
| Download | Get the compressed image archive from the **Assets** section of the [NIGHTHAWK OS 1.0 release](https://github.com/sbdhkfl/NIGHTHAWK-OS-RELEASE/releases) |
| Extracted image size | 1,768,947,712 bytes (1.65 GiB, **1.77 GB**) |
| SHA256 of extracted image | `126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885` |
| Format | Compressed download containing a raw disk image; extract before flashing |
| Architecture | ARM64 / AArch64 |
| SoC | Allwinner H618 (4x Cortex-A53) |
| Kernel | Armbian `6.18.57-current-sunxi64` (unmodified) |
| Boot chain | Armbian U-Boot/SPL (`eGON.BT0` at 8 KiB), `boot.scr` → `armbianEnv.txt` |
| Packages | 565 |
| Partition layout | MBR, partition 1 at sector 8192, ext4, label `nighthawk` |

The downloadable archive is provided as a release asset because the raw disk
image is too large for normal Git repository file uploads. The archive must be
extracted to obtain the `.img` file. **Do not flash the archive itself.**

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

1. Download the compressed image archive from the release **Assets** section.
2. Extract the archive (see [FLASHING.md](FLASHING.md) for Windows, macOS, and Linux instructions).
3. Verify the extracted `.img` file using the SHA256 checksum in [FLASHING.md](FLASHING.md).
4. Write the extracted image to a microSD card (8 GB or larger).
5. Insert the card, connect HDMI + USB keyboard, and power on with a 5 V/3 A supply.
6. Complete the first-boot setup wizard to create your user and set passwords.

Full details: `FLASHING.md`, `HARDWARE-COMPATIBILITY.md`, `TROUBLESHOOTING.md`,
and `BUILD-REPORT.md` (how it was built and exactly what was verified).

## Initial login credentials — choose by platform

### PC / laptop image — Release 3 (x86_64)

The graphical live-session login uses:

| Field | Value |
|---|---|
| Username | `user` |
| Password | `live` |

These are public default credentials for the **PC live session**. They are not the Orange Pi credentials. If you keep using this account, change its password after logging in. For an installed system, create a personal account during installation or first setup and use that account for everyday work.

### Orange Pi Zero 3 images — Releases 1 and 2 (ARM64)

The Orange Pi images use their own board-specific first-boot setup. Follow the Orange Pi instructions in this README and `FLASHING.md`; do not use the PC `user` / `live` credentials for the ARM64 image.

### Security notes

- Do not enable password-based root SSH.
- Create a personal non-root account for everyday administration and grant sudo access only as needed.
- UFW is installed but **not enabled** in the documented ARM image; enable it after setup if appropriate: `sudo ufw allow ssh && sudo ufw enable`.

## Platform releases

- **Release 1:** Orange Pi Zero 3, ARM64, without Wi-Fi.
- **Release 2:** Orange Pi Zero 3, ARM64, with Wi-Fi.
- **Release 3:** Intel/AMD desktops and laptops, x86_64 PC ISO.

The PC ISO and Orange Pi images are separate builds. Never flash an ARM64 image to a PC or the x86_64 ISO to an Orange Pi. Hardware compatibility depends on the specific machine; Secure Boot and firmware requirements are described in the PC release notes.

See the [multi-platform architecture plan](https://github.com/sbdhkfl/NIGHTHAWK-OS/blob/main/docs/MULTI-PLATFORM.md) for target status and release criteria.
