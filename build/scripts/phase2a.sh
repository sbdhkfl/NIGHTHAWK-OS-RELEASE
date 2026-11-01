#!/bin/bash
# NIGHTHAWK OS - Phase 2a: read Armbian firstboot flow + zram defaults + misc (run as root)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/opt/nh-build
cd "$WORK" || exit 1
LOOP=$(losetup -f --show -P "$WORK/armbian-minimal.img") || { echo "FATAL losetup"; exit 1; }
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL mount"; losetup -d "$LOOP"; exit 1; }
M=/mnt/armbian
{
echo "=== armbian-firstrun.service ==="
cat $M/etc/systemd/system/armbian-firstrun.service 2>/dev/null || cat $M/lib/systemd/system/armbian-firstrun.service 2>/dev/null
echo "=== armbian-firstrun (head 90) ==="
head -90 $M/usr/lib/armbian/armbian-firstrun
echo "=== firstlogin PRESET conf path ==="
grep -nE 'PRESET_|firstrun\.conf|firstboot|\.conf' $M/usr/lib/armbian/armbian-firstlogin | head -30
echo "=== firstlogin head 60 ==="
head -60 $M/usr/lib/armbian/armbian-firstlogin
echo "=== aw859a services ==="
for u in $M/etc/systemd/system/aw859a-*.service $M/lib/systemd/system/aw859a-*.service; do [ -f "$u" ] && { echo "-- $u"; cat "$u"; }; done 2>/dev/null
echo "=== armbian-common config keys ==="
grep -nE '^[A-Z_]+=' $M/usr/lib/armbian/armbian-common | head -40
echo "=== zram default conf ==="
cat $M/etc/default/armbian-zram-config 2>/dev/null || echo "none (ENABLED=false in script)"
echo "=== root hash candidates ==="
HASH=$(grep '^root:' $M/etc/shadow | cut -d: -f2)
echo "hash=${HASH:0:30}..."
if command -v perl >/dev/null; then
  for pw in 1234 armbian kali root nighthawk password; do
    perl -e 'my ($h,$p)=@ARGV; my $r=crypt($p,$h); print ($r eq $h ? "MATCH:$p\n" : "no:$p\n")' "$HASH" "$pw"
  done
else echo "no perl"; fi
echo "=== misc ==="
cat $M/etc/hostname
ls -l $M/etc/os-release $M/etc/hostname
cat $M/etc/default/locale 2>/dev/null
grep -E '^#? ?(en_US|C)\.UTF-8' $M/etc/locale.gen 2>/dev/null | head -3
readlink -f $M/etc/systemd/system/default.target; cat $M/etc/systemd/system/default.target 2>/dev/null || ls -l $M/lib/systemd/system/default.target
echo "-- xsessions --"; ls $M/usr/share/xsessions/ 2>/dev/null || echo none
echo "-- dtb du --"; du -sh $M/boot/dtb-* 2>/dev/null
echo "-- firmware package depends --"
dpkg --root=$M -s armbian-firmware 2>/dev/null | grep -E '^(Package|Version|Depends|Recommends)' 
dpkg --root=$M -l 2>/dev/null | grep -cE '^ii'
echo "-- armbian-config pkg --"
dpkg --root=$M -l 2>/dev/null | grep -E '^ii +(armbian|ncdu|network-manager|firmware)' | head
} 2>&1
umount $M
losetup -d "$LOOP"
echo "=== DONE ==="
