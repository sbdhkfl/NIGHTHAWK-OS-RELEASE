#!/bin/bash
# Phase 4e: recover interrupted dpkg transaction, finish configuration, verify
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4e.log
exec > >(tee "$LOG") 2>&1

echo "=== start $(date) ==="
for d in dev dev/pts proc sys; do
  mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done
[ -f "$R/etc/resolv.conf" ] || echo "nameserver 1.1.1.1" > "$R/etc/resolv.conf"

echo "=== policy-rc.d ==="
ls -l "$R/usr/sbin/policy-rc.d" 2>&1 || printf '#!/bin/sh\nexit 101\n' > "$R/usr/sbin/policy-rc.d"
chmod +x "$R/usr/sbin/policy-rc.d"

echo "=== dpkg journal recovery ==="
chroot "$R" env DEBIAN_FRONTEND=noninteractive dpkg --configure -a
echo "configure-a exit=$?"

echo "=== apt -f install ==="
chroot "$R" env DEBIAN_FRONTEND=noninteractive apt-get -f install -y --no-install-recommends
echo "apt-f exit=$?"

echo "=== audit ==="
chroot "$R" dpkg --audit; echo "audit done"
echo "=== end $(date) ==="
