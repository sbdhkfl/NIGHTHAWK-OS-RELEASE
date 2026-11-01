#!/bin/bash
# NIGHTHAWK OS - Phase 2: unpack Armbian base into rootfs workdir + trim firmware (run as ROOT)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -o pipefail
WORK=/home/kali/nh-build
LOG="$WORK/phase2.log"
IMG="$WORK/armbian-minimal.img"
R="$WORK/rootfs"
exec > >(tee -a "$LOG") 2>&1

echo "=== phase2 start $(date -u +%FT%TZ) ==="

echo "[1] attach source image"
LOOP=$(losetup -f --show -P "$IMG") || { echo "FATAL losetup"; exit 1; }
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL mount"; losetup -d "$LOOP"; exit 1; }
echo "    loop=$LOOP"

echo "[2] prepare workdir $R"
mkdir -p "$R"

echo "[3] copy rootfs (rsync -aHAX, numeric ids)"
rsync -aHAX --numeric-ids /mnt/armbian/ "$R"/ || { echo "FATAL rsync"; exit 1; }

echo "[4] detach source image"
umount /mnt/armbian
losetup -d "$LOOP"

echo "[5] firmware trim (keep only H618-relevant blobs)"
FW="$R/lib/firmware"
if [ -d "$FW" ]; then
  before=$(du -sm "$FW" | cut -f1)
  mkdir -p "$WORK/firmware-keep"
  # uwe5622 = Unisoc combo WiFi/BT on Orange Pi Zero 3 (H618)
  for p in uwe5622 uwe5621ds wcnmodem.bin regulatory.db; do
    if [ -e "$FW/$p" ]; then
      mkdir -p "$WORK/firmware-keep/$(dirname "$p")"
      cp -a "$FW/$p" "$WORK/firmware-keep/$p"
    fi
  done
  rm -rf "$FW"/*
  cp -a "$WORK/firmware-keep/." "$FW"/
  after=$(du -sm "$FW" | cut -f1)
  echo "    firmware: ${before}MB -> ${after}MB"
else
  echo "    WARNING: no $FW"
fi

echo "[6] rootfs size after trim"
du -sm "$R" | cut -f1 | xargs -I{} echo "    rootfs = {}MB"

echo "[7] chroot mounts"
mount --bind /dev "$R/dev"
mount -t proc proc "$R/proc"
mount -t sysfs sysfs "$R/sys"
mount -t devpts devpts "$R/dev/pts"
mount --move /run "$R/run" 2>/dev/null || true

echo "[8] DNS for chroot"
cp --remove-destination /etc/resolv.conf "$R/etc/resolv.conf" 2>/dev/null || \
  { rm -f "$R/etc/resolv.conf"; cp /etc/resolv.conf "$R/etc/resolv.conf"; }

echo "[9] verify chroot can execute arm64 binaries (qemu binfmt)"
chroot "$R" /bin/bash -c 'echo "  chroot OK: $(uname -m)"' || echo "  FATAL chroot exec"

echo "[10] debootstrap kali-rolling variant availability (for Kali repo/keyring plan)"
ls -l "$R/usr/share/keyrings/" 2>/dev/null | grep -i kali || echo "  no kali keyring in Armbian base (expected)"

echo "=== phase2 done $(date -u +%FT%TZ) ==="
echo "LOG=$LOG"
