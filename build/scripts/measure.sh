#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
echo "=== verify desktop ==="
for b in /usr/sbin/lightdm /usr/bin/startxfce4 /usr/bin/xfce4-session; do
  [ -e "$R$b" ] && echo "OK      $b" || echo "MISSING $b"
done
echo "=== exact used bytes ==="
du -sbx --exclude=proc --exclude=sys --exclude=dev "$R" | cut -f1
echo "=== candidates ==="
for p in usr/share/doc usr/share/man usr/share/locale usr/share/icons usr/share/fonts var/lib/apt/lists var/cache usr/share/help usr/lib/python3 usr/share/zoneinfo usr/lib/firmware usr/share/i18n; do
  printf "%-22s %s\n" "$p" "$(du -shx "$R/$p" 2>/dev/null | cut -f1)"
done
echo "=== locales present ==="
ls "$R/usr/share/locale" | tr '\n' ' '
echo
echo "=== zram unit ==="
ls "$R/usr/lib/systemd/system/" | grep -i zram || echo none
echo "=== which zram pkg ==="
chroot "$R" dpkg -l 2>/dev/null | grep -i zram
