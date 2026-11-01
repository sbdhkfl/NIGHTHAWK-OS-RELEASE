# Build Report — NIGHTHAWK OS 1.0 for Orange Pi Zero 3

Date: 2026-11-01
Produced image: `nighthawk-os-1.0-orangepi-zero3-arm64.img`
SHA256: `126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885`
Size: 1,768,947,712 bytes (**1.77 GB**, meets the "under 2 GB" requirement)

## 1. Why the Kali VirtualBox image was not used as the base

The starting artifact was `kali-linux-2026.2-virtualbox-amd64` (x86_64 VDI).

| Problem | Consequence |
|---|---|
| x86_64 userspace (glibc 2.43) | Cannot execute on ARM64 H618; every binary is the wrong architecture |
| No Allwinner boot chain | No SPL/U-Boot for H618, no `sun50i-h618` device tree |
| VDI is a virtual disk container | Not a flashable raw SD image |
| GRUB i386-pc bootloader | Meaningless on Allwinner BootROM |

**Decision: keep the tested Armbian H618 boot chain and transplant the Kali
identity onto it** (repositories + keyring + package model + branding) instead
of trying to force an x86 image onto ARM. The kernel, U-Boot, DTB and initramfs
are exactly the Armbian-supplied ones.

Base: `Armbian_community_26.11.0-trunk.108_Orangepizero3_trixie_current_6.18.57_minimal`
(336,437,100 bytes compressed → 1,619,001,344 bytes raw, partition 1 at
sector 8192, type `0x83`).

## 2. Build steps (all reproducible from `build/`)

1. **Host prep** — `debootstrap`, `qemu-user-binfmt`; `qemu-aarch64` binfmt
   registered so ARM64 packages can be configured in a chroot.
2. **Inspect the base image** — layout, `/boot` contents, enabled services,
   firmware size (491 MB → trimmed to 3.5 MB, keeping only UWE5622 Wi-Fi/BT
   blobs and the regulatory database).
3. **Rootfs extraction** — `rsync -aHAX --numeric-ids` to
   `/home/kali/nh-build/rootfs`, bind-mount `/dev`, `/dev/pts`, `/proc`, `/sys`,
   verify `chroot` runs ARM64 binaries.
4. **Kali integration** — install `kali-archive-keyring` (world-readable, so
   apt's `_apt` user can open it), add
   `deb [signed-by=...] http://http.kali.org/kali kali-rolling main contrib
   non-free non-free-firmware`, and pin: Debian 990 / Kali 500 / trixie-security
   990. Kali arm64 indexes were fetched successfully during the build.
5. **Package installation** (`--no-install-recommends` everywhere):
   - core: nmap, ufw, lynis, tcpdump, dnsutils, openssh client+server, curl,
     wget, git, python3, python3-venv
   - browser: firefox-esr 153.6.0esr
   - desktop: XFCE4 (session, panel, settings, thunar, terminal, appfinder,
     power-manager, screenshooter, clipman), xfwm4, xfdesktop4, LightDM + GTK
     greeter, xserver-xorg-core + libinput, polkitd, lxpolkit, NetworkManager +
     nm-applet, btop
6. **Identity + branding** — hostname `nighthawk`, `/etc/os-release`,
   `/etc/nighthawk-release`, MOTD, profile.d, crimson GTK2/GTK3 theme, icon
   theme, wallpaper, LightDM greeter theme, XFCE defaults in `/etc/skel`,
   Firefox policies + system prefs, `nighthawk` helper command, security
   helper scripts.
7. **Services** — enable LightDM (via `display-manager.service`),
   NetworkManager, `armbian-zram-config`; disable `systemd-networkd*` and the
   standalone `wpa_supplicant.service` (NetworkManager owns Wi-Fi); keep
   Armbian's first-run/resize and Wi-Fi/BT helper units; delete SSH host keys
   so they are regenerated on first boot.
8. **Size trim** — removed apt lists, non-English locales, doc bodies (kept
   copyright), Python caches and logs: 1,714,460,000 → 1,386,500,461 bytes.
9. **Image assembly** — copy the first 4 MiB (MBR + SPL + U-Boot) verbatim from
   the pristine Armbian image, create a partition at sector 8192 (type `0x83`,
   MBR id preserved `0x59037350`), `mkfs.ext4 -m 0 -J size=32 -L nighthawk`,
   rsync the rootfs, then rewrite **both** boot references to the new UUID:
   `/boot/armbianEnv.txt` (`rootdev=UUID=...`) and `/etc/fstab`.

## 3. Problems hit during the build (and fixes)

| Problem | Effect | Fix |
|---|---|---|
| `xfdesktop` is not a Debian trixie package | first desktop install aborted atomically | correct name is `xfdesktop4`; package names verified with `apt-cache policy` before installing |
| `network-manager-gnome` pulls `ukui-polkit` → Qt5 + OpenCV + GDAL (~250 MB) | would have broken the 2 GB budget | replaced with `network-manager-applet` + `lxpolkit` (147 packages instead of 236) |
| Host restarted mid-install | ~100 libraries unpacked but unconfigured; dpkg journal in `updates/` | `dpkg --configure -a`, then `apt-get -f install`; orphans removed with `apt-get --purge autoremove` |
| `rsync` of the rootfs without `-x` followed the bind-mounted `/proc` | filled the new partition ("no space left on device") | rebuilt with `rsync -aHAXx --numeric-ids --exclude=/proc,/sys,/dev` |
| Guest file copy denied | image was root-owned `0600`/`0640` | `chmod 644` before `VBoxManage guestcontrol copyfrom` |

## 4. Verification performed (automated)

Run against the **finished image**, mounted read-only:

| Check | Result |
|---|---|
| `sfdisk -d` layout | partition 1, start 8192, type 0x83 ✔ |
| U-Boot signature at 8 KiB | `\002\0\0\352 e G O N` (`eGON.BT0`) ✔ |
| `fsck.ext4 -fn` | clean, 34,401 files, 0.2% non-contiguous ✔ |
| Boot payload | `boot.scr`, `Image`→kernel, `uInitrd`, H618 DTB all present ✔ |
| Rootfs UUID consistency | `armbianEnv.txt rootdev` == `/etc/fstab` == partition UUID ✔ |
| ELF architecture | 0 x86-64 binaries in `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin`, `/usr/lib`, `/lib` ✔ |
| Desktop binaries | lightdm, startxfce4, thunar, xfce4-terminal, xfwm4, xfdesktop, NetworkManager, nm-applet, lxpolkit ✔ |
| Security tools | nmap, lynis, tcpdump, ufw, dig, ssh, git, python3, curl ✔ |
| Service wiring | `display-manager.service → lightdm.service`, NetworkManager wanted, zram linked ✔ |
| `dpkg --audit` | clean ✔ |
| Package count | 565 ✔ |
| SSH policy | `PermitRootLogin no`, `PasswordAuthentication no` ✔ |
| Kali repo + keyring | repository file present, keyring 1193 bytes, mode 644 ✔ |
| Branding assets | os-release, motd, wallpaper, GTK/icon themes, LightDM conf, Firefox prefs, `nighthawk` helper, first-boot preset ✔ |

**Not verified:** physical boot on an Orange Pi Zero 3, HDMI output, Wi-Fi/BT
bring-up, Ethernet link, USB, thermal behaviour, suspend. No board was available;
those items are covered by `build/hardware-testing-checklist.md`. There is no
substitute for testing on the real hardware.

## 5. Security notes and honest limitations

- The Armbian first-login wizard runs on the console via a temporary root
  autologin and forces a new root password plus creation of a user. Until it is
  completed, the console is unprotected — that is inherent to shipping an image
  with no pre-made accounts. SSH cannot be used to reach that state (root login
  and password auth are disabled).
- UFW is installed but intentionally **not** enabled, so a mistake cannot lock
  you out of a headless board; enable it after the first login.
- Removing non-English locales and package documentation saves space at the cost
  of localized UI text and on-disk changelogs. Re-add with
  `apt install locales-all` or `apt install --reinstall <pkg>`.
- The rootfs image has ~200 MB free before first-boot resize; the resize unit
  grows it to the card's full size.
- Kali packages come from the rolling channel and can drift from the pinned
  Debian base; upgrades may occasionally require `-t kali-rolling` or
  `apt full-upgrade`.
