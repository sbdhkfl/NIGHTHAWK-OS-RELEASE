#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
echo "=== binaries ==="
for b in /usr/sbin/lightdm /usr/bin/lightdm /usr/bin/startxfce4 /usr/bin/xfwm4 /usr/bin/xfce4-panel /usr/bin/thunar /usr/bin/xfce4-terminal /usr/sbin/NetworkManager /usr/bin/nm-applet /usr/bin/btop /usr/bin/xfdesktop; do
  [ -e "$R$b" ] && echo "OK      $b" || echo "MISSING $b"
done
echo "=== counts ==="
echo "packages: $(chroot "$R" dpkg-query -f '.\n' -W | wc -l)"
echo "=== size (excluding mounts) ==="
du -shx --exclude=proc --exclude=sys --exclude=dev "$R"
echo "=== top dirs ==="
du -shx "$R"/usr "$R"/var "$R"/opt "$R"/home "$R"/root 2>/dev/null
echo "=== why gdal/opencv ==="
chroot "$R" bash -c 'apt-cache rdepends --installed libgdal36 2>/dev/null | head -20; echo ---; apt-cache rdepends --installed libopencv-core410 2>/dev/null | head -20'
echo "=== autoremove dry run ==="
chroot "$R" apt-get --purge autoremove -s 2>/dev/null | tail -5
echo "=== enabled services ==="
ls "$R/etc/systemd/system/multi-user.target.wants/" | head -40
