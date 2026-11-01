#!/bin/bash
IMG=/home/kali/nh-build/nighthawk-os-1.0-orangepi-zero3-arm64.img
for l in $(losetup -j "$IMG" | cut -d: -f1); do losetup -d "$l" || true; done
loop=$(losetup -f --show -P -r "$IMG"); part="${loop}p1"; [ -b "$part" ] || part="${loop}1"
mount -o ro "$part" /mnt/v; V=/mnt/v
echo "=== toolkit paths ==="
for b in usr/sbin/lynis usr/bin/nmtui usr/sbin/tcpdump usr/sbin/ufw usr/bin/dig usr/bin/ssh usr/bin/git usr/bin/python3 usr/bin/curl; do
  [ -e "$V/$b" ] && echo "OK      /$b" || echo "MISSING /$b"
done
echo "=== xsession/greeter ==="
ls "$V/usr/share/xsessions/" 2>/dev/null
grep -E "user-session|greeter-session" "$V/etc/lightdm/lightdm.conf"
echo "=== misc ==="
cat "$V/etc/resolv.conf"; readlink "$V/etc/localtime" 2>/dev/null; cat "$V/etc/timezone" 2>/dev/null
echo "=== sshd effective config check ==="
grep -h . "$V/etc/ssh/sshd_config.d/"*.conf
echo "=== firefox cfg head ==="
head -5 "$V/usr/lib/firefox-esr/nighthawk.cfg"
echo "=== xfce skel ==="
find "$V/etc/skel" -type f | head
echo "=== sizes ==="
du -sh "$V"/usr/share/icons "$V"/usr/share/themes "$V"/usr/share/backgrounds 2>/dev/null
echo "=== x86 leftovers in /usr/lib (full scan) ==="
find "$V/usr" "$V/lib" -type f -name '*.so*' -print0 2>/dev/null | xargs -0 file 2>/dev/null | grep -c 'x86-64' || true
umount /mnt/v; losetup -d "$loop"
echo done
