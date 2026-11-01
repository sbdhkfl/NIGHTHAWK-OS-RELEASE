#!/bin/bash
# Phase 6b: assemble image (fixed rsync: no crossing into bind mounts)
set -eu
R=/home/kali/nh-build/rootfs
BASE=/home/kali/nh-build/armbian-minimal.img
OUT=/home/kali/nh-build/nighthawk-os-1.0-orangepi-zero3-arm64.img
LOG=/home/kali/nh-build/phase6b.log
exec > >(tee "$LOG") 2>&1

# clear any leftover state from the failed run
umount -R /mnt/nh 2>/dev/null || true
for l in $(losetup -j "$OUT" 2>/dev/null | cut -d: -f1); do losetup -d "$l" || true; done
rm -rf /mnt/nh

[ -f "$BASE" ] || { echo "FATAL: base image missing"; exit 1; }
used=$(du -sbx --exclude=proc --exclude=sys --exclude=dev "$R" | cut -f1)
extra=$((360*1024*1024))
psize=$(( (used + extra + 1048575) / 1048576 * 1048576 ))
psec=$(( psize / 512 ))
total=$(( (8192 + psec) * 512 ))
echo "rootfs used=$used partition=$psize total=$total"
[ "$total" -lt 2000000000 ] || { echo "FATAL: exceeds 2 GB"; exit 1; }

dd if="$BASE" of="$OUT" bs=1M count=4 status=none
truncate -s "$total" "$OUT"

cat > /tmp/nh-pt <<EOF
label: dos
label-id: 0x59037350
unit: sectors
start=8192, size=$psec, type=83
EOF
sfdisk --quiet --no-tell-kernel "$OUT" < /tmp/nh-pt
sfdisk -d "$OUT"

loop=$(losetup -f --show -P "$OUT")
trap 'umount -R /mnt/nh 2>/dev/null; losetup -d "$loop" 2>/dev/null' EXIT
part="${loop}p1"
[ -b "$part" ] || part="${loop}1"
mkfs.ext4 -q -F -m 0 -L nighthawk -J size=32 "$part"

mkdir -p /mnt/nh
mount "$part" /mnt/nh
echo "=== rsync ==="
rsync -aHAXx --numeric-ids --exclude=/proc --exclude=/sys --exclude=/dev "$R/" /mnt/nh/
sync

echo "=== point boot at new rootfs UUID ==="
newuuid=$(blkid -s UUID -o value "$part")
echo "new rootfs UUID=$newuuid"
sed -i "s|^rootdev=.*|rootdev=UUID=$newuuid|" /mnt/nh/boot/armbianEnv.txt
sed -i "s|^UUID=[^[:space:]]*|UUID=$newuuid|" /mnt/nh/etc/fstab
grep -n rootdev /mnt/nh/boot/armbianEnv.txt
cat /mnt/nh/etc/fstab
grep -q "^UUID=$newuuid" /mnt/nh/etc/fstab || { echo "FATAL: fstab UUID not updated"; exit 1; }
[ -e /mnt/nh/proc/kcore ] && { echo "FATAL: /proc was copied"; exit 1; }

echo "=== boot payload ==="
for f in boot/boot.scr boot/Image boot/uInitrd boot/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb; do
  [ -e "/mnt/nh/$f" ] && echo "OK      /$f" || echo "MISSING /$f"
done
du -sh /mnt/nh; df -h /mnt/nh | tail -1

sync
umount /mnt/nh
trap - EXIT
echo "=== fsck ==="
fsck.ext4 -fn "$part" 2>&1 | tail -4 || true
losetup -d "$loop"

echo "=== result ==="
ls -l "$OUT"
sha256sum "$OUT" | tee "$OUT.sha256"
dd if="$OUT" bs=1 skip=8192 count=8 status=none | od -c | head -2
