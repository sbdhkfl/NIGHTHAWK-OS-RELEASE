#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
for p in xfce-polkit lxpolkit nm-tray xfce4-network-manager-plugin policykit-1-gnome mate-polkit network-manager-applet gvfs thunar-volman xfce4-notifyd tumbler; do
  v=$(chroot "$R" apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2}')
  echo "$p -> ${v:-MISSING}"
done
echo "=== sim without nm-gnome ==="
chroot "$R" apt-get install -s --no-install-recommends --no-remove \
 lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput \
 xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal \
 xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin \
 polkitd xfce-polkit network-manager btop 2>&1 | grep -E "newly installed|After this operation|^E:"
