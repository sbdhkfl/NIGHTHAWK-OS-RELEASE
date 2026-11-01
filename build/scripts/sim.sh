#!/bin/bash
set -u
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
PKGS="lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput \
xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal \
xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin \
polkitd network-manager network-manager-gnome btop"
chroot "$R" apt-get install -s --no-install-recommends --no-remove $PKGS > /tmp/sim.txt 2>&1
grep -E "newly installed|After this operation|Need to get" /tmp/sim.txt
echo "=== new package names ==="
grep -E "^Inst " /tmp/sim.txt | awk '{print $2}' | sort | tr '\n' ' ' | fold -w 160
echo
echo "=== gdal/opencv/qt present? ==="
grep -E "gdal|opencv|qt5" /tmp/sim.txt | head -20
