#!/bin/bash
# NIGHTHAWK OS build - Phase 1: download Armbian image (boot-chain source for OPi Zero 3) and inspect layout
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/home/kali/nh-build
URL="https://github.com/armbian/community/releases/download/26.11.0-trunk.108/Armbian_community_26.11.0-trunk.108_Orangepizero3_trixie_current_6.18.57_minimal.img.xz"
mkdir -p "$WORK" || { echo "FATAL: mkdir $WORK"; exit 1; }
cd "$WORK" || exit 1

echo "=== download ==="
if [ ! -f "$WORK/armbian-minimal.img" ] && [ ! -s "$WORK/armbian-minimal.img.xz" ]; then
  wget -O "$WORK/armbian-minimal.img.xz" "$URL" 2>&1 | tail -3
fi

echo "=== decompress ==="
if [ ! -f "$WORK/armbian-minimal.img" ]; then
  xz -dc "$WORK/armbian-minimal.img.xz" > "$WORK/armbian-minimal.img" || { echo "FATAL: xz"; exit 1; }
  rm -f "$WORK/armbian-minimal.img.xz"
fi
ls -l "$WORK/armbian-minimal.img"

echo "=== partition table ==="
sfdisk -l "$WORK/armbian-minimal.img"
echo "--- dump ---"
sfdisk -d "$WORK/armbian-minimal.img" > "$WORK/armbian.layout"
cat "$WORK/armbian.layout"

echo "=== first 1MB hexdump (U-Boot placement) ==="
xxd -l 1024 "$WORK/armbian-minimal.img" | head -20
echo "--- offset 8KiB (typical sunxi SPL) ---"
dd if="$WORK/armbian-minimal.img" bs=1 skip=8192 count=64 2>/dev/null | xxd | head -4

echo "=== loop attach + mount rootfs (sudo) ==="
PW=kali

echo "$PW" | sudo -S -p '' bash -s -- "$WORK/armbian-minimal.img" "$WORK/inspect1.log" <<'EOS'
set -o pipefail
IMG="$1"
LOG="$2"
LOOP=$(losetup -f --show -P "$IMG") || { echo "FATAL: losetup"; exit 1; }
echo "loop=$LOOP"
mkdir -p /mnt/armbian
ls -l ${LOOP}p* 2>&1
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL: mount p1"; losetup -d "$LOOP"; exit 1; }

{
echo "--- / ---"
ls -la /mnt/armbian
echo "--- /boot ---"
ls -la /mnt/armbian/boot
echo "--- /boot/extlinux ---"
ls -la /mnt/armbian/boot/extlinux 2>&1
cat /mnt/armbian/boot/extlinux/extlinux.conf 2>&1
echo "--- extlinux/*.conf any ---"
cat /mnt/armbian/boot/extlinux/*.conf 2>&1
echo "--- kernel/initrd present ---"
ls -l /mnt/armbian/boot/uImage /mnt/armbian/boot/zImage /mnt/armbian/boot/vmlinuz* /mnt/armbian/boot/initrd* /mnt/armbian/boot/initramfs* 2>&1
echo "--- modules ---"
ls -d /mnt/armbian/lib/modules/* 2>&1
echo "--- DTB for h618 ---"
ls -l /mnt/armbian/lib/modules/*/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb 2>&1
ls -l /mnt/armbian/boot/dtb/allwinner/sun50i-h618* 2>&1
find /mnt/armbian -name 'sun50i-h618*' 2>/dev/null | head -10
echo "--- firmware ---"
du -sh /mnt/armbian/lib/firmware 2>&1
echo "--- root fstab ---"
cat /mnt/armbian/etc/fstab 2>&1
echo "--- armbian-release ---"
cat /mnt/armbian/etc/armbian-release 2>&1
echo "--- u-boot env / scr files ---"
ls -l /mnt/armbian/boot/*.scr /mnt/armbian/boot/*.cmd 2>&1
echo "--- disk usage rootfs ---"
du -sh /mnt/armbian 2>/dev/null
} > "$LOG" 2>&1

tail -100 "$LOG"
umount /mnt/armbian 2>&1
losetup -d "$LOOP" 2>&1
EOS

echo "=== DONE ==="
