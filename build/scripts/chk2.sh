#!/bin/bash
R=/home/kali/nh-build/rootfs
echo "=== display manager ==="
ls -l "$R/etc/systemd/system/display-manager.service" 2>&1
ls "$R/etc/systemd/system/graphical.target.wants/" 2>&1
echo "=== networkd/wpa masked state ==="
ls -l "$R/etc/systemd/system/" | grep -E "networkd|wpa_supplicant" || echo "no symlinks"
echo "=== zram ==="
find "$R/etc/systemd/system" -name '*zram*' -printf '%p -> %l\n' 2>/dev/null
echo "=== fstab ==="
cat "$R/etc/fstab"
echo "=== armbianEnv rootdev ==="
grep -i rootdev "$R/boot/armbianEnv.txt"
echo "=== boot dir ==="
ls -la "$R/boot" | head -20
