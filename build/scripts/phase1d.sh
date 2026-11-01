#!/bin/bash
# NIGHTHAWK OS build - Phase 1d: apt sources + network + firmware keep-list (run as ROOT)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/home/kali/nh-build
IMG="$WORK/armbian-minimal.img"
LOG="$WORK/inspect3.log"
LOOP=$(losetup -f --show -P "$IMG") || { echo "FATAL: losetup"; exit 1; }
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL: mount"; losetup -d "$LOOP"; exit 1; }

{
echo "=== debian.sources ==="
cat /mnt/armbian/etc/apt/sources.list.d/debian.sources
echo "=== armbian.sources ==="
cat /mnt/armbian/etc/apt/sources.list.d/armbian.sources
echo "=== armbian-config.sources ==="
cat /mnt/armbian/etc/apt/sources.list.d/armbian-config.sources
echo "=== NetworkManager conf ==="
ls -R /mnt/armbian/etc/NetworkManager 2>&1 | head -30
cat /mnt/armbian/etc/NetworkManager/NetworkManager.conf 2>&1
echo "=== NM conf.d ==="
cat /mnt/armbian/etc/NetworkManager/conf.d/* 2>&1 | head -40
echo "=== NM system-connections ==="
ls -la /mnt/armbian/etc/NetworkManager/system-connections/ 2>&1
echo "=== policykit rules (nm) ==="
ls /mnt/armbian/etc/polkit-1/localauthority/50-local.d/ 2>&1
cat /mnt/armbian/etc/polkit-1/localauthority/50-local.d/*network* 2>&1 | head -20
echo "=== firmware KEEP candidates (non-qcom/ath/intel/mediatek/etc) ==="
du -sh /mnt/armbian/lib/firmware/uwe5622 /mnt/armbian/lib/firmware/uwe5621ds /mnt/armbian/lib/firmware/wcnmodem.bin /mnt/armbian/lib/firmware/regulatory.db 2>&1
ls /mnt/armbian/lib/firmware/*.bin /mnt/armbian/lib/firmware/*.txt /mnt/armbian/lib/firmware/*.db 2>&1 | head -30
echo "=== bluetooth firmware (H618 BT via uwe5622) ==="
find /mnt/armbian/lib/firmware -maxdepth 2 -iname '*uwe5622*' -o -iname '*bluetooth*' 2>/dev/null | grep -iv ath | head -20
echo "=== overlays dir (dtbo) ==="
ls /mnt/armbian/boot/dtb/allwinner/overlay/ 2>&1 | head -20
echo "=== how many dtbo ==="
ls /mnt/armbian/boot/dtb/allwinner/overlay/ 2>/dev/null | wc -l
echo "=== boot/dtb total size ==="
du -sh /mnt/armbian/boot/dtb 2>&1
echo "=== sudoers ==="
ls -l /mnt/armbian/etc/sudoers /mnt/armbian/etc/sudoers.d/ 2>&1
cat /mnt/armbian/etc/sudoers 2>&1 | grep -vE '^#|^$' | head -20
} > "$LOG" 2>&1

tail -120 "$LOG"
umount /mnt/armbian 2>&1
losetup -d "$LOOP" 2>&1
echo "=== DONE ==="
