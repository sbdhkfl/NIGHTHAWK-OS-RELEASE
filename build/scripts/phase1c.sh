#!/bin/bash
# NIGHTHAWK OS build - Phase 1c: read Armbian boot config + firmware breakdown (run as ROOT)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/home/kali/nh-build
IMG="$WORK/armbian-minimal.img"
LOG="$WORK/inspect2.log"
LOOP=$(losetup -f --show -P "$IMG") || { echo "FATAL: losetup"; exit 1; }
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL: mount"; losetup -d "$LOOP"; exit 1; }

{
echo "=== armbianEnv.txt ==="
cat /mnt/armbian/boot/armbianEnv.txt
echo
echo "=== boot.cmd ==="
cat /mnt/armbian/boot/boot.cmd
echo
echo "=== firmware top-level breakdown ==="
du -sh /mnt/armbian/lib/firmware/* 2>/dev/null | sort -rh | head -25
echo "=== firmware: what uwe5622/wcn needs (H618 WiFi) ==="
find /mnt/armbian/lib/firmware -maxdepth 2 -iname '*uwe*' -o -maxdepth 2 -iname '*wcn*' -o -maxdepth 2 -iname '*sprd*' 2>/dev/null | head -20
echo "=== modules: wifi/bt drivers present ==="
find /mnt/armbian/lib/modules/6.18.57-current-sunxi64 -iname '*sprdwl*' -o -iname '*wcn*' -o -iname '*bluetooth*' 2>/dev/null | head -15
echo "=== rootfs du breakdown (top dirs) ==="
du -sh /mnt/armbian/* 2>/dev/null | sort -rh | head -20
echo "=== etc/network + connman/networkd ==="
ls /mnt/armbian/etc/systemd/network 2>&1 | head
ls -d /mnt/armbian/etc/NetworkManager /mnt/armbian/usr/sbin/connmand /mnt/armbian/usr/sbin/NetworkManager 2>&1
echo "=== existing users/groups in image ==="
grep -E 'home|sh$' /mnt/armbian/etc/passwd | head -20
echo "=== apt sources ==="
cat /mnt/armbian/etc/apt/sources.list 2>&1
ls /mnt/armbian/etc/apt/sources.list.d/ 2>&1
echo "=== debootstrap? kali? ==="
cat /mnt/armbian/etc/os-release 2>&1
echo "=== sudo/wheel ==="
ls -l /mnt/armbian/usr/bin/sudo 2>&1
grep -E 'sudo|wheel' /mnt/armbian/etc/group 2>&1
} > "$LOG" 2>&1

tail -140 "$LOG"
umount /mnt/armbian 2>&1
losetup -d "$LOOP" 2>&1
echo "=== DONE ==="
