#!/bin/bash
# Phase 4c: verify dpkg state, refresh lists, resolve correct trixie package names for XFCE/LightDM
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4c.log
exec > >(tee "$LOG") 2>&1

echo "=== remount chroot ==="
for d in dev dev/pts proc sys; do
  mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done
[ -f "$R/etc/resolv.conf" ] || echo "nameserver 1.1.1.1" > "$R/etc/resolv.conf"

echo "=== dpkg audit ==="
chroot "$R" dpkg --audit || true

echo "=== apt lists present ==="
ls -1 "$R/var/lib/apt/lists/" | head -20

echo "=== apt sources ==="
cat "$R"/etc/apt/sources.list.d/* 2>/dev/null

echo "=== apt update ==="
chroot "$R" apt-get update 2>&1 | tail -15

echo "=== candidate names ==="
chroot "$R" bash -c '
for p in xfce4 xfce4-session xfce4-panel xfce4-settings xfce4-terminal xfwm4 xfdesktop4 thunar xfce4-appfinder xfce4-power-manager xfce4-screenshooter xfce4-clipman-plugin lightdm lightdm-gtk-greeter polkitd xserver-xorg-core network-manager btop; do
  v=$(apt-cache policy "$p" 2>/dev/null | awk "/Candidate:/{print \$2}")
  echo "$p -> ${v:-MISSING}"
done'

echo "=== done ==="
