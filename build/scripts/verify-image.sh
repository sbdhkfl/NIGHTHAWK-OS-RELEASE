#!/bin/bash
# Phase 7: verify the assembled image (mount read-only, check contents)
set -u
IMG=/home/kali/nh-build/nighthawk-os-1.0-orangepi-zero3-arm64.img
OUT=/home/kali/nh-build/verification.log
exec > >(tee "$OUT") 2>&1

umount -R /mnt/v 2>/dev/null || true
for l in $(losetup -j "$IMG" | cut -d: -f1); do losetup -d "$l" || true; done
loop=$(losetup -f --show -P -r "$IMG")
part="${loop}p1"; [ -b "$part" ] || part="${loop}1"
mkdir -p /mnt/v
mount -o ro "$part" /mnt/v
V=/mnt/v

echo "=== image ==="
ls -l "$IMG"; sfdisk -d "$IMG" | tail -2
echo "=== identity ==="
grep -E "^(PRETTY_NAME|ID|ID_LIKE|VERSION_ID)" "$V/etc/os-release"
cat "$V/etc/hostname"; cat "$V/etc/nighthawk-release"
echo "=== arch sanity (all ELF must be ARM aarch64) ==="
bad=$(find "$V/usr/bin" "$V/usr/sbin" "$V/bin" "$V/sbin" "$V/usr/lib" -maxdepth 2 -type f -print0 2>/dev/null |
      xargs -0 file 2>/dev/null | grep -c 'ELF.*x86-64' || true)
echo "x86-64 ELF files: $bad"
file -L "$V/usr/bin/xfce4-session" | sed 's/.*: //'
file -L "$V/lib/systemd/systemd" | sed 's/.*: //'
echo "=== desktop stack ==="
for b in usr/sbin/lightdm usr/bin/startxfce4 usr/bin/thunar usr/bin/xfce4-terminal \
         usr/bin/xfwm4 usr/bin/xfdesktop usr/sbin/NetworkManager usr/bin/nm-applet \
         usr/bin/lxpolkit usr/bin/btop usr/bin/firefox-esr usr/sbin/sshd usr/bin/nmap usr/bin/lynis; do
  [ -e "$V/$b" ] && echo "OK      /$b" || echo "MISSING /$b"
done
echo "=== service wiring ==="
readlink "$V/etc/systemd/system/display-manager.service"
readlink "$V/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
readlink "$V/etc/systemd/system/sysinit.target.wants/armbian-zram-config.service" 2>/dev/null || echo "zram: not linked"
ls "$V/etc/systemd/system/multi-user.target.wants/" | tr '\n' ' '; echo
echo "=== networkd/wpa ==="
ls "$V/etc/systemd/system/" | grep -E 'networkd|wpa' || echo "disabled"
echo "=== boot chain ==="
grep -E '^(rootdev|fdtfile|overlay_prefix|verbosity)' "$V/boot/armbianEnv.txt"
cat "$V/etc/fstab"
ls "$V/boot/boot.scr" "$V/boot/uInitrd" "$V/boot/Image" "$V/boot/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb" >/dev/null && echo "boot payload OK"
echo "=== branding ==="
for f in usr/share/backgrounds/nighthawk-wallpaper.png usr/share/themes/Nighthawk/gtk-3.0/gtk.css \
         usr/share/icons/NightHawk/index.theme etc/motd etc/profile.d/nighthawk.sh \
         etc/lightdm/lightdm.conf etc/lightdm/lightdm-gtk-greeter.conf \
         etc/sysctl.d/99-nighthawk.conf etc/ssh/sshd_config.d/99-nighthawk.conf \
         etc/firefox-esr/policies/policies.json usr/lib/firefox-esr/nighthawk.cfg \
         usr/local/bin/nighthawk root/.not_logged_in_yet; do
  [ -e "$V/$f" ] && echo "OK      /$f" || echo "MISSING /$f"
done
echo "=== kali integration ==="
cat "$V"/etc/apt/sources.list.d/*kali* 2>/dev/null
ls -l "$V/etc/apt/keyrings/kali-archive-keyring.gpg"
cat "$V/etc/apt/preferences.d/nighthawk" 2>/dev/null | head -20
echo "=== packages ==="
chroot "$V" dpkg-query -f '.\n' -W 2>/dev/null | wc -l
chroot "$V" dpkg --audit 2>&1 | head -5
echo "root password state: $(awk -F: '$1=="root"{print $2}' "$V/etc/shadow" | cut -c1-3)..."
echo "=== first boot wiring ==="
head -3 "$V/root/.not_logged_in_yet"
cat "$V/etc/systemd/system/getty@tty1.service.d/override.conf"
echo "=== disk usage in image ==="
df -h /mnt/v | tail -1
du -sh "$V" 2>/dev/null | tail -1

umount /mnt/v
losetup -d "$loop"
echo "=== verification complete ==="
