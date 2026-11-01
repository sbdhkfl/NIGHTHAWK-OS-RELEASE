#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
R=/home/kali/nh-build/rootfs

echo "=== resolv.conf state ==="
ls -l "$R/etc/resolv.conf" 2>&1
echo "--- host resolv ---"
cat /etc/resolv.conf 2>&1 | head -8
echo "--- inside-chroot resolv ---"
cat "$R/etc/resolv.conf" 2>&1 | head -8

echo "=== write STATIC resolv.conf (Cloudflare+Google, no bind mount) ==="
# drop any bind mount / symlink, write a plain file
umount "$R/etc/resolv.conf" 2>/dev/null || true
rm -f "$R/etc/resolv.conf"
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 9.9.9.9\n' > "$R/etc/resolv.conf"
chmod 644 "$R/etc/resolv.conf"
ls -l "$R/etc/resolv.conf"
echo "--- verify a plain file (not symlink/mount) ---"
stat -c '%F' "$R/etc/resolv.conf"

echo "=== DNS test from inside chroot ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  getent hosts http.kali.org 2>&1 | head -4

echo "=== apt-get update (Kali should now resolve) ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-get update 2>&1 | grep -iE 'kali|err|fail' | head -15

echo "=== Kali repo visible now? ==="
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-cache policy 2>&1 | grep -iE 'kali' | head -10

echo "=== DONE ==="
