#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
R=/home/kali/nh-build/rootfs
echo "=== current keyring perms ==="
ls -l "$R/etc/apt/keyrings/kali-archive-keyring.gpg"
echo "=== fix perms: world-readable (apt _apt user must read) ==="
chmod 755 "$R/etc/apt/keyrings"
chmod 644 "$R/etc/apt/keyrings/kali-archive-keyring.gpg"
chown root:root "$R/etc/apt/keyrings/kali-archive-keyring.gpg"
ls -l "$R/etc/apt/keyrings/kali-archive-keyring.gpg"
echo "=== apt-get update ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-get update 2>&1 | grep -iE 'kali|err|fail|armbian|release' | head -20
echo "=== Kali repo now visible? ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-cache policy 2>&1 | grep -iE 'kali' | head -10
echo "=== DONE ==="
