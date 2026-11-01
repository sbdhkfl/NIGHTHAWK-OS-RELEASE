#!/bin/bash
# NIGHTHAWK OS - Phase 1e: deep inspect Armbian rootfs + Kali VM facts (run as root)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/opt/nh-build
cd "$WORK" || exit 1
LOOP=$(losetup -f --show -P "$WORK/armbian-minimal.img") || { echo "FATAL losetup"; exit 1; }
mount -o ro ${LOOP}p1 /mnt/armbian || { echo "FATAL mount"; losetup -d "$LOOP"; exit 1; }
{
echo "=== os-release ==="
cat /mnt/armbian/etc/os-release
echo "=== users/shadow ==="
grep -vE '^(#|$)' /mnt/armbian/etc/passwd
grep -E '^(root|kali|user|nobody):' /mnt/armbian/etc/shadow 2>/dev/null | cut -d: -f1,2 | head
ls /mnt/armbian/home/
echo "=== enabled units ==="
ls /mnt/armbian/etc/systemd/system/multi-user.target.wants/ 2>/dev/null
echo "-- graphical --"
ls /mnt/armbian/etc/systemd/system/graphical.target.wants/ 2>/dev/null
echo "-- getty --"
ls /mnt/armbian/etc/systemd/system/getty.target.wants/ 2>/dev/null
echo "=== firstrun script ==="
ls /mnt/armbian/usr/lib/armbian/ 2>/dev/null | head -30
ls /mnt/armbian/usr/sbin/ | grep -iE 'armbian|firstrun|firstlogin' | head
echo "=== PRESET refs ==="
grep -rl 'PRESET_' /mnt/armbian/usr/lib/armbian/ /mnt/armbian/usr/sbin/ 2>/dev/null | head -5
echo "=== zram ==="
cat /mnt/armbian/usr/lib/armbian/armbian-zram-config 2>/dev/null | head -30 || find /mnt/armbian -name '*zram*' -not -path '*/lib/modules/*' 2>/dev/null | head
echo "=== services presence ==="
ls -l /mnt/armbian/usr/sbin/NetworkManager 2>&1 | head -1
ls -l /mnt/armbian/usr/sbin/sshd 2>&1 | head -1
ls -l /mnt/armbian/usr/bin/sudo 2>&1 | head -1
ls -d /mnt/armbian/usr/sbin/growpart /mnt/armbian/usr/sbin/resize2fs 2>&1
echo "=== dpkg packages of interest ==="
chroot /mnt/armbian dpkg-query -W -f='${Package} ${Version}\n' network-manager openssh-server sudo armbian-firmware armbian-firmware-full firmware-realtek firmware-brcm80211 locales 2>&1 | head -20
echo "=== apt sources ==="
cat /mnt/armbian/etc/apt/sources.list 2>/dev/null
for f in /mnt/armbian/etc/apt/sources.list.d/*; do echo "-- $f"; cat "$f"; done 2>/dev/null
echo "=== apt preferences ==="
ls /mnt/armbian/etc/apt/preferences.d/ 2>/dev/null && head -50 /mnt/armbian/etc/apt/preferences.d/* 2>/dev/null
echo "=== firmware kept candidates ==="
du -sh /mnt/armbian/lib/firmware/brcm /mnt/armbian/lib/firmware/rtw88 /mnt/armbian/lib/firmware/rtw89 /mnt/armbian/lib/firmware/rtl_bt /mnt/armbian/lib/firmware/rtlwifi /mnt/armbian/lib/firmware/regulatory.db 2>&1
ls /mnt/armbian/lib/firmware/ | grep -iE '^(rtw|rtl|brcm|xr)' | head -20
echo "=== UWE5622 (20U5622 wifi chip) driver+firmware ==="
find /mnt/armbian/lib/modules/6.18.57-current-sunxi64 -iname '*uwe5622*' -o -iname '*marlin*' -o -iname '*8723d*' 2>/dev/null | head -15
ls /mnt/armbian/lib/firmware/ | grep -iE 'uwe|marlin|spreadtrum|sc2|20u' 
du -sh /mnt/armbian/lib/firmware/uwe5622 2>/dev/null
grep -rE 'uwe5622|20U5622' /mnt/armbian/etc/modprobe.d/ /mnt/armbian/etc/modules-load.d/ /mnt/armbian/etc/initramfs-tools/ 2>/dev/null | head -10
ls /mnt/armbian/etc/modules-load.d/ 2>/dev/null && cat /mnt/armbian/etc/modules-load.d/* 2>/dev/null | head -20
echo "=== which firmware dirs reference uwe5622 (from kernel modules) ==="
grep -r 'uwe5622' /mnt/armbian/lib/modules/6.18.57-current-sunxi64/modules.alias 2>/dev/null | head -3
find /mnt/armbian/lib/modules/6.18.57-current-sunxi64/kernel/drivers -maxdepth 3 -type d -iname '*uwe*' -o -maxdepth 3 -type d -iname '*wlan*' 2>/dev/null | head
echo "=== total rootfs ==="
du -sh /mnt/armbian 2>/dev/null
echo "=== boot dtb size ==="
du -sh /mnt/armbian/boot/dtb 2>/dev/null
echo "=== resize unit ==="
cat /mnt/armbian/etc/systemd/system/armbian-resize-filesystem.service 2>/dev/null || cat /mnt/armbian/lib/systemd/system/armbian-resize-filesystem.service 2>/dev/null
echo "=== firstlogin ==="
find /mnt/armbian -name '*firstlogin*' -not -path '*/lib/modules/*' 2>/dev/null | head
} 2>&1
umount /mnt/armbian
losetup -d "$LOOP"

{
echo "===== KALI VM FACTS ====="
echo "=== kali sources.list ==="
cat /etc/apt/sources.list 2>/dev/null
ls /etc/apt/sources.list.d/ 2>/dev/null && head -20 /etc/apt/sources.list.d/* 2>/dev/null
echo "=== kali keyring ==="
ls -l /usr/share/keyrings/kali* /etc/apt/trusted.gpg.d/kali* 2>/dev/null
dpkg-query -W -f='${Package} ${Version}\n' kali-archive-keyring 2>/dev/null
echo "=== kali libc6 ==="
dpkg-query -W -f='${Package} ${Version}\n' libc6 2>/dev/null
echo "=== kali vdi partition table (original image) ==="
sfdisk -l /dev/sda 2>&1
echo "=== kali grub ==="
ls /boot/grub/ | head -5
} 2>&1
echo "=== DONE ==="
