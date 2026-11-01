#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do
  mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done
echo "=== dpkg.log tail ==="
tail -12 "$R/var/log/dpkg.log"
echo "=== dpkg audit ==="
chroot "$R" dpkg --audit
echo "=== packages ==="
chroot "$R" dpkg -l | grep -E "lightdm|xfce4|xfdesktop|thunar|xfwm4|network-manager|polkit|^ii  xorg|xserver" | awk '{print $1,$2,$3}'
echo "=== dpkg updates dir ==="
ls -1 "$R/var/lib/dpkg/updates/" 2>/dev/null | head
echo "=== phase4d.log tail ==="
tail -20 /home/kali/nh-build/phase4d.log 2>/dev/null
echo "=== apt history ==="
tail -25 "$R/var/log/apt/history.log" 2>/dev/null
echo "=== size ==="
du -sh "$R"
df -h /home/kali | tail -1
