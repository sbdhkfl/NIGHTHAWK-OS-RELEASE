#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
for p in lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput \
 xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal \
 xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin \
 polkitd network-manager network-manager-gnome; do
  n=$(chroot "$R" apt-get install -s --no-install-recommends --no-remove "$p" 2>/dev/null | grep -cE "^Inst (libgdal36|libopencv-core410)")
  echo "$p -> gdal/opencv pkgs: $n"
done
echo "=== rdepends of libgdal36 (all) ==="
chroot "$R" apt-cache rdepends libgdal36 2>/dev/null | tail -n +3 | tr -d ' |' | tr '\n' ' '
echo
echo "=== rdepends of libopencv-core410 (all) ==="
chroot "$R" apt-cache rdepends libopencv-core410 2>/dev/null | tail -n +3 | tr -d ' |' | tr '\n' ' '
