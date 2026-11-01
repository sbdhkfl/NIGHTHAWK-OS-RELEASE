#!/bin/bash
# NIGHTHAWK OS build - Phase 1b: inspect downloaded Armbian image (run as ROOT)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/home/kali/nh-build
IMG="$WORK/armbian-minimal.img"
LOG="$WORK/inspect1.log"
[ -f "$IMG" ] || { echo "FATAL: no image at $IMG"; exit 1; }

mkdir -p /mnt/armbian
LOOP=$(losetup -f --show -P "$IMG") || { echo "FATAL: losetup"; exit 1; }
echo "loop=$LOOP"
ls -l ${LOOP}p* 2>&1
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL: mount p1"; losetup -d "$LOOP"; exit 1; }

{
echo "--- / ---"
ls -la /mnt/armbian
echo "--- /boot ---"
ls -la /mnt/armbian/boot
echo "--- /boot/extlinux ---"
ls -la /mnt/armbian/boot/extlinux 2>&1
echo "--- extlinux.conf ---"
cat /mnt/armbian/boot/extlinux/extlinux.conf 2>&1
echo "--- extlinux/*.conf ---"
cat /mnt/armbian/boot/extlinux/*.conf 2>&1
echo "--- kernel/initrd ---"
ls -l /mnt/armbian/boot/uImage /mnt/armbian/boot/zImage /mnt/armbian/boot/vmlinuz* /mnt/armbian/boot/initrd* /mnt/armbian/boot/initramfs* 2>&1
echo "--- modules ---"
ls -d /mnt/armbian/lib/modules/* 2>&1
echo "--- DTB h618 ---"
ls -l /mnt/armbian/lib/modules/*/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb 2>&1
ls -l /mnt/armbian/boot/dtb/allwinner/sun50i-h618* 2>&1
find /mnt/armbian -name 'sun50i-h618*' 2>/dev/null | head -10
echo "--- firmware ---"
du -sh /mnt/armbian/lib/firmware 2>&1
echo "--- fstab ---"
cat /mnt/armbian/etc/fstab 2>&1
echo "--- armbian-release ---"
cat /mnt/armbian/etc/armbian-release 2>&1
echo "--- scr/cmd ---"
ls -l /mnt/armbian/boot/*.scr /mnt/armbian/boot/*.cmd 2>&1
echo "--- rootfs size ---"
du -sh /mnt/armbian 2>/dev/null
} > "$LOG" 2>&1

echo "tail -100:"
tail -100 "$LOG"
umount /mnt/armbian 2>&1
losetup -d "$LOOP" 2>&1
echo "=== DONE ==="
