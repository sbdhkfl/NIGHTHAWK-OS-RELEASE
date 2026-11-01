#!/bin/bash
# NIGHTHAWK OS - Phase 2c: firstlogin autologin paths + preset file + root pw handling (run as root)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/opt/nh-build
cd "$WORK" || exit 1
LOOP=$(losetup -f --show -P "$WORK/armbian-minimal.img") || exit 1
mount -o ro ${LOOP}p1 /mnt/armbian || { losetup -d "$LOOP"; exit 1; }
M=/mnt/armbian
{
echo "=== check-first-login.sh ==="
cat $M/etc/profile.d/armbian-check-first-login.sh
echo "=== fp_config definition ==="
grep -n 'fp_config' $M/usr/lib/armbian/armbian-firstlogin | head -10
echo "=== firstlogin 795-870 (autologin removal) ==="
sed -n '795,870p' $M/usr/lib/armbian/armbian-firstlogin
echo "=== root password handling ==="
grep -n 'PRESET_ROOT_PASSWORD\|root password\|passwd root\|chpasswd' $M/usr/lib/armbian/armbian-firstlogin | head -15
echo "=== timers enabled ==="
ls $M/etc/systemd/system/timers.target.wants/ 2>/dev/null || echo none
echo "=== firmware updates dir ==="
du -sh $M/lib/firmware/updates 2>/dev/null; ls $M/lib/firmware/updates/ 2>/dev/null | head
du -sh $M/lib/firmware/rtl_nic $M/lib/firmware/xr819 2>/dev/null
echo "=== lightdm default conf present? ==="
ls $M/etc/lightdm/ 2>/dev/null || echo "no /etc/lightdm (package not installed)"
echo "=== polkit pkla networkmanager (bsp) ==="
head -8 $M/var/lib/polkit-1/localauthority/50-local.d/networkmanager.pkla 2>/dev/null
} 2>&1
umount $M
losetup -d "$LOOP"
echo "=== DONE ==="
