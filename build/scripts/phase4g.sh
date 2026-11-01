#!/bin/bash
# Phase 4g: install minimal XFCE + LightDM + NM applet (no recommends)
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4g.log
exec > >(tee "$LOG") 2>&1
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done

PKGS="lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput \
xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal \
xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin \
polkitd lxpolkit network-manager network-manager-applet btop"

echo "=== start $(date) ==="
chroot "$R" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends --no-remove $PKGS
echo "=== apt exit=$? $(date) ==="

echo "=== verify ==="
for b in /usr/sbin/lightdm /usr/bin/startxfce4 /usr/bin/xfwm4 /usr/bin/xfce4-panel \
         /usr/bin/thunar /usr/bin/xfce4-terminal /usr/sbin/NetworkManager /usr/bin/nm-applet \
         /usr/bin/xfdesktop /usr/bin/btop /usr/bin/xfce4-screenshooter; do
  [ -e "$R$b" ] && echo "OK      $b" || echo "MISSING $b"
done
echo "=== audit ==="
chroot "$R" dpkg --audit; echo "audit-done"
chroot "$R" apt-get clean
echo "=== size ==="
du -shx --exclude=proc --exclude=sys --exclude=dev "$R"
echo "=== end $(date) ==="
