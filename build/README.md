# Build scripts — NIGHTHAWK OS 1.0 (Orange Pi Zero 3)

These are the exact scripts used to produce the released image, kept for audit
and rebuild. They were run **inside a Kali x86_64 VirtualBox guest** using
`qemu-user-binfmt` to configure ARM64 packages in a chroot.

Paths used during the build:

| Path | Meaning |
|---|---|
| `/home/kali/nh-build/armbian-minimal.img` | pristine Armbian base image (never modified) |
| `/home/kali/nh-build/rootfs` | working ARM64 root filesystem |
| `/home/kali/nh-src` | NIGHTHAWK branding/config assets (from `Downloads/OS`) |
| `/home/kali/nh-build/*.log` | build logs (copied to `logs/`) |

## Prerequisites

```bash
sudo apt install debootstrap qemu-user-binfmt binfmt-support rsync dosfstools \
                 e2fsprogs util-linux
sudo systemctl restart systemd-binfmt
# verify: echo 'int main(){}' > /tmp/t.c && aarch64-linux-gnu-gcc /tmp/t.c -o /tmp/t
```

Base image (do not modify it):

```
Armbian_community_26.11.0-trunk.108_Orangepizero3_trixie_current_6.18.57_minimal.img
```

## Order of execution

| Step | Script | What it does |
|---|---|---|
| 0 | `phase0.sh` | host prerequisites, binfmt check |
| 1x | `phase1*.sh` | download/inspect the Armbian image, boot and network facts |
| 2 | `phase2*.sh` | extract rootfs, trim firmware to the UWE5622 blobs, bind mounts, chroot check |
| 3 | `phase3*.sh` | Kali keyring, Kali repo, apt pinning, arm64 index verification |
| 4 | `phase4.sh` | core + security + browser packages, locale |
| 4c/4d | `phase4c.sh`, `phase4d.sh` | package-name discovery and the first (aborted) desktop attempt — kept for history |
| 4e | `recover.sh` | `dpkg --configure -a` + `apt -f install` after the host restart |
| 4f | `prune.sh` | remove the orphaned library set (Qt5/OpenCV/GDAL pulled by `network-manager-gnome`) |
| 4g | `phase4g.sh` | **desktop install**: XFCE4 + LightDM + NetworkManager + nm-applet + lxpolkit |
| 5 | `phase5.sh` | identity, branding, deskop defaults, services, first-boot wiring |
| 5b | `phase5b.sh` | size trim (apt lists, non-English locales, doc bodies) |
| 6b | `phase6b.sh` | **image assembly** (the version that was used; `phase6.sh` is the earlier run that followed the bind-mounted `/proc`) |
| 7 | `verify-image.sh`, `verify2.sh` | read-only verification of the finished image |

Helper scripts (`sim.sh`, `blame.sh`, `names*.sh`, `measure.sh`, `poll*.sh`,
`check.sh`, `chk2.sh`, `verify*.sh`) are diagnostics used along the way; they are
included so every decision in `../BUILD-REPORT.md` can be re-checked.

## Rebuilding from scratch

1. Download and decompress the Armbian base image to
   `/home/kali/nh-build/armbian-minimal.img`.
2. Unpack the NIGHTHAWK assets to `/home/kali/nh-src`.
3. Run `phase2*.sh` → `phase3*.sh` → `phase4.sh` → `phase4g.sh` → `phase5.sh`
   → `phase5b.sh` → `phase6b.sh` in that order.
4. Compare the resulting SHA256 with `../SHA256SUMS`. Byte-identical output is
   not guaranteed (package versions in Kali rolling move, timestamps, UUIDs),
   but the verification table in `../BUILD-REPORT.md` should reproduce.

## Notes / gotchas baked into the scripts

- Always use `--no-install-recommends`; without it the desktop pulls hundreds of
  MB of extras and blows the 2 GB image budget.
- Never install `network-manager-gnome`: it depends on `ukui-polkit`, which
  drags in Qt5 + OpenCV + GDAL (~250 MB).
- The Debian package name is `xfdesktop4`, not `xfdesktop`.
- `rsync` of the rootfs **must** use `-x` (or exclude `/proc`, `/sys`, `/dev`),
  otherwise the bind-mounted host `/proc` is copied into the image.
- Both `/boot/armbianEnv.txt` (`rootdev=UUID=...`) and `/etc/fstab` must be
  updated to the new rootfs UUID after `mkfs`.
- Kali keyring permissions matter: `/etc/apt/keyrings` 755, key file 644, or
  apt's `_apt` user fails with "Permission denied".
- Chroot DNS: a static `/etc/resolv.conf` inside the rootfs is needed because a
  bind-mounted `/run` breaks `getaddrinfo` in the chroot.
