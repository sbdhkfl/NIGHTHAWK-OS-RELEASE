#!/bin/bash
# Phase 4d: install minimal XFCE + LightDM + NetworkManager (no recommends)
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4d.log
exec > >(tee "$LOG") 2>&1

for d in dev dev/pts proc sys; do
  mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done

PKGS="lightdm lightdm-gtk-greeter xserver-xorg-core xserver-xorg-input-libinput \
xfce4-session xfwm4 xfce4-panel xfce4-settings xfdesktop4 thunar xfce4-terminal \
xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin \
polkitd network-manager network-manager-gnome btop"

echo "=== install start $(date) ==="
chroot "$R" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-remove $PKGS
rc=$?
echo "=== apt exit=$rc ==="

echo "=== verify binaries ==="
for b in /usr/bin/lightdm /usr/sbin/lightdm /usr/bin/startxfce4 /usr/bin/thunar /usr/bin/xfce4-terminal /usr/bin/xfwm4-network-manager /usr/sbin/NetworkManager; do
  [ -e "$R$b" ] && echo "OK $b" || echo "MISSING $b"
done

echo "=== dpkg audit ==="
chroot "$R" dpkg --audit || true
echo "=== disk ==="
du -sh "$R"
echo "=== done $(date) ==="
