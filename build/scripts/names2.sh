#!/bin/bash
R=/home/kali/nh-build/rootfs
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
BASE="lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin polkitd network-manager btop"
echo "### option A: nm-applet + lxpolkit"
chroot "$R" apt-get install -s --no-install-recommends --no-remove $BASE network-manager-applet lxpolkit 2>&1 | grep -E "newly installed|After this operation|^E:|ukui-polkit|libgdal36"
echo "### option B: nm-tray + lxpolkit"
chroot "$R" apt-get install -s --no-install-recommends --no-remove $BASE nm-tray lxpolkit 2>&1 | grep -E "newly installed|After this operation|^E:|ukui-polkit|libgdal36"
echo "### option C: no tray"
chroot "$R" apt-get install -s --no-install-recommends --no-remove $BASE lxpolkit 2>&1 | grep -E "newly installed|After this operation|^E:"
