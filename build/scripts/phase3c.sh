#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
R=/home/kali/nh-build/rootfs
echo "=== kali.list present? ==="
ls -l "$R/etc/apt/sources.list.d/kali.list" 2>&1
echo "=== keyring present? ==="
ls -l "$R/etc/apt/keyrings/kali-archive-keyring.gpg" 2>&1
echo "=== keyring valid gpg? ==="
gpg --no-default-keyring --keyring "$R/etc/apt/keyrings/kali-archive-keyring.gpg" --list-keys 2>&1 | head -8
echo "=== key file size ==="
ls -l /tmp/kali-key.asc 2>&1
head -2 /tmp/kali-key.asc 2>&1
echo "=== apt-get update FULL output (watch for kali errors) ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root apt-get update 2>&1 | grep -iE 'kali|err|fail|warn' | head -25
echo "=== apt list files downloaded ==="
ls -la "$R/var/lib/apt/lists/" 2>&1 | grep -i kali | head
echo "=== DONE ==="
