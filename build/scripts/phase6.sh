#!/bin/bash
# Phase 6: assemble flashable Orange Pi Zero 3 image from Armbian boot region + NIGHTHAWK rootfs
set -eu
R=/home/kali/nh-build/rootfs
BASE=/home/kali/nh-build/armbian-minimal.img
OUT=/home/kali/nh-build/nighthawk-os-1.0-orangepi-zero3-arm64.img
LOG=/home/kali/nh-build/phase6.log
exec > >(tee "$LOG") 2>&1

[ -f "$BASE" ] || { echo "FATAL: base image missing"; exit 1; }
used=$(du -sbx --exclude=proc --exclude=sys --exclude=dev "$R" | cut -f1)
extra=$((360*1024*1024))
psize=$(( (used + extra + 1048575) / 1048576 * 1048576 ))
psec=$(( psize / 512 ))
total=$(( (8192 + psec) * 512 ))
echo "rootfs used=$used partition=$psize total=$total"
if [ "$total" -ge 2000000000 ]; then echo "FATAL: image would exceed 2 GB ($total bytes)"; exit 1; fi

echo "=== boot region (MBR + U-Boot, first 4 MiB of pristine Armbian image) ==="
dd if="$BASE" of="$OUT" bs=1M count=4 status=none
truncate -s "$total" "$OUT"

echo "=== partition table ==="
cat > /tmp/nh-pt <<EOF
label: dos
label-id: 0x59037350
unit: sectors
start=8192, size=$psec, type=83
EOF
sfdisk --quiet --no-tell-kernel "$OUT" < /tmp/nh-pt
sfdisk -d "$OUT"

echo "=== filesystem ==="
loop=$(losetup -f --show -P "$OUT")
trap 'umount -R /mnt/nh 2>/dev/null; losetup -d "$loop" 2>/dev/null' EXIT
part="${loop}p1"
[ -b "$part" ] || part="${loop}1"
mkfs.ext4 -q -F -m 0 -L nighthawk -J size=32 "$part"

echo "=== copy rootfs ==="
mkdir -p /mnt/nh
mount "$part" /mnt/nh
rsync -aHAX --numeric-ids "$R/" /mnt/nh/
sync

echo "=== point boot at new rootfs UUID ==="
newuuid=$(blkid -s UUID -o value "$part")
echo "new rootfs UUID=$newuuid"
sed -i "s|^rootdev=.*|rootdev=UUID=$newuuid|" /mnt/nh/boot/armbianEnv.txt
sed -i "s|^UUID=[^[:space:]]*|UUID=$newuuid|" /mnt/nh/etc/fstab
grep -n rootdev /mnt/nh/boot/armbianEnv.txt
cat /mnt/nh/etc/fstab
grep -n "^UUID=$newuuid" /mnt/nh/etc/fstab >/dev/null || { echo "FATAL: fstab UUID not updated"; exit 1; }

echo "=== boot payload check ==="
for f in boot/boot.scr boot/Image boot/uInitrd boot/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb; do
  [ -e "/mnt/nh/$f" ] && echo "OK      /$f" || echo "MISSING /$f"
done
ls -l /mnt/nh/boot/ | head -8

sync
umount /mnt/nh
trap - EXIT
echo "=== fsck ==="
fsck.ext4 -fn "$part" 2>&1 | tail -5 || true
losetup -d "$loop"

echo "=== checksums ==="
ls -l "$OUT"
sha256sum "$OUT" | tee "$OUT.sha256"
echo "=== u-boot signature at 8 KiB ==="
dd if="$OUT" bs=1 skip=8192 count=8 status=none | od -c | head -2
