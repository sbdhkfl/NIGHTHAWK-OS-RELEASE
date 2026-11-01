# Hardware Compatibility — NIGHTHAWK OS 1.0

Target board: **Orange Pi Zero 3**, SoC **Allwinner H618**.

## Status legend

- **In image** — present and configured; verified by inspecting the built image.
- **Boot-path verified** — verified at the artifact level (bootloader signature,
  partition table, kernel/DTB/uInitrd present, rootfs UUID wired into both
  `armbianEnv.txt` and `/etc/fstab`).
- **Not physically tested** — no Orange Pi Zero 3 board was available during
  this build. Nothing below was validated on real hardware.

## Board support

| Component | Detail | Status |
|---|---|---|
| SoC / CPU | Allwinner H618, 4x Cortex-A53, ARM64 | In image (Armbian kernel `6.18.57-current-sunxi64`) |
| RAM | 2 GB (primary target) and 4 GB variant | In image — same image runs on both; zram sized `ram/4` |
| GPU | Mali-G31 MP2 | Mesa userspace + `modesetting` X driver in image; no XFCE compositor by default |
| HDMI | micro-HDMI output | Kernel/DTB in image; **not physically tested** |
| Ethernet | Gigabit MAC on H618 | NetworkManager in image; **not physically tested** |
| Wi-Fi | Unisoc UWE5622 (SDIO) | Firmware trimmed to `uwe5622/`, `uwe5621ds/`, `wcnmodem.bin`, `regulatory.db`; `aw859a-wifi.service` enabled |
| Bluetooth | UWE5622 UART side | Firmware kept; `aw859a-bluetooth.service` enabled |
| microSD | Boot medium | **Boot-path verified** |
| USB 2.0 host | 2 ports | Kernel support; **not physically tested** |
| Serial console | UART0 header | Getty autologin available; pinout per Orange Pi Zero 3 docs |
| Thermal | `thermal_zone0` | Reported by `nighthawk sysinfo` |

## Boot chain (unchanged from Armbian)

| Offset / path | Content | Verified |
|---|---|---|
| 8 KiB | SPL, `eGON.BT0` magic | Yes — byte-for-byte from the pristine Armbian image |
| 128 KiB region | U-Boot | Yes — copied verbatim, first 4 MiB |
| Sector 8192 | Partition 1 (MBR type `0x83`, ext4, label `nighthawk`) | Yes |
| `/boot/boot.scr` | U-Boot script → `armbianEnv.txt` | Yes |
| `/boot/armbianEnv.txt` | `rootdev=UUID=<new rootfs UUID>` | Yes, matches `/etc/fstab` |
| `/boot/Image` → `vmlinuz-6.18.57-current-sunxi64` | Kernel | Yes |
| `/boot/uInitrd` | Initramfs for U-Boot | Yes |
| `/boot/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb` | Device tree | Yes |

The kernel, U-Boot, DTB and initramfs were **not** rebuilt or replaced; only the
root filesystem changed. This keeps the board's tested boot path intact.

## Storage / first boot

- Image is 1.77 GB; first boot runs `armbian-resize-filesystem` and grows the
  partition/filesystem to the full card capacity.
- MicroSD 8 GB or larger recommended (Class 10 / A1 or better).
- Power: 5 V / 3 A supply via USB-C. Undervoltage is the most common cause of
  random reboots and SD corruption on this board.

## Known limitations

- No prior NIGHTHAWK/Kali ARM64 image existed for this board; this build is a
  first integration. Expect to iterate on Wi-Fi/BT bring-up on real hardware.
- Desktop compositing is disabled by design (GPU acceleration on H618 with
  mainline Mesa is limited); software rendering is used.
- KVM/accelerated virtualization is not available on H618.
- The image is ARM64 only. It cannot boot on x86_64 PCs, and the original Kali
  VirtualBox image cannot boot on this board (see `BUILD-REPORT.md`).
- Only the Orange Pi Zero 3 is targeted; other H618 boards are untested.

## Physical test checklist

`build/hardware-testing-checklist.md` contains the step-by-step bring-up list
(HDMI, Ethernet, Wi-Fi, BT, USB, thermal, suspend, audio) to run once a board is
available.
