#!/bin/bash
# NIGHTHAWK OS - Phase 2b: firstboot autologin mechanism + preset path + firstrun env (run as root)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORK=/opt/nh-build
cd "$WORK" || exit 1
LOOP=$(losetup -f --show -P "$WORK/armbian-minimal.img") || exit 1
mount -o ro ${LOOP}p1 /mnt/armbian || { losetup -d "$LOOP"; exit 1; }
M=/mnt/armbian
{
echo "=== getty tty1 dropins ==="
ls -l $M/etc/systemd/system/getty@tty1.service.d/ 2>/dev/null && cat $M/etc/systemd/system/getty@tty1.service.d/* 2>/dev/null || echo "NO dropin dir"
echo "=== disable-autologin unit+timer ==="
cat $M/lib/systemd/system/armbian-disable-autologin.service 2>/dev/null
cat $M/lib/systemd/system/armbian-disable-autologin.timer 2>/dev/null
cat $M/etc/systemd/system/armbian-disable-autologin.timer 2>/dev/null
echo "=== who invokes firstlogin ==="
grep -rn 'not_logged_in_yet\|armbian-firstlogin' $M/root/ $M/etc/profile $M/etc/profile.d/ $M/etc/bash.bashrc $M/etc/skel/ 2>/dev/null | head -10
echo "=== firstlogin source lines ==="
grep -nE '^[[:space:]]*(\.|source)[[:space:]]' $M/usr/lib/armbian/armbian-firstlogin | head -15
echo "=== firstlogin preset file refs ==="
grep -nE 'preset|PRESET_FILE|firstlogin.conf|\.preset' $M/usr/lib/armbian/armbian-firstlogin | grep -iE 'source|\. |file=' | head -10
echo "=== /etc/default/armbian-firstrun ==="
cat $M/etc/default/armbian-firstrun 2>/dev/null || echo none
echo "=== autologin refs in armbian scripts ==="
grep -rn 'autologin' $M/usr/lib/armbian/ 2>/dev/null | head -10
echo "=== units wants full ==="
ls -l $M/etc/systemd/system/multi-user.target.wants/ | head -30
echo "=== graphical wants ==="
ls -l $M/etc/systemd/system/graphical.target.wants/ 2>/dev/null || echo none
echo "=== sshd default config key lines ==="
grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|#PermitRootLogin)' $M/etc/ssh/sshd_config | head
ls $M/etc/ssh/sshd_config.d/ 2>/dev/null && cat $M/etc/ssh/sshd_config.d/* 2>/dev/null | head -20
echo "=== zram service unit ==="
cat $M/lib/systemd/system/armbian-zram-config.service 2>/dev/null | head -25
echo "=== armbian-bsp provides ==="
dpkg --root=$M -L armbian-bsp-cli-orangepizero3-current 2>/dev/null | head -25
} 2>&1
umount $M
losetup -d "$LOOP"
echo "=== DONE ==="
