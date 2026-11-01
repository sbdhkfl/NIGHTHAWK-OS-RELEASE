#!/bin/bash
# NIGHTHAWK OS build - Phase 0: install build dependencies in the Kali VM
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive
PW=kali

echo "=== installing packages ==="
echo "$PW" | sudo -S -p '' apt-get install -y -qq \
  debootstrap qemu-user-binfmt qemu-user binfmt-support \
  fdisk gdisk e2fsprogs xz-utils rsync dosfstools mtools 2>&1 | tail -15

echo "=== debootstrap kali scripts ==="
ls /usr/share/debootstrap/scripts/ | grep -i -E 'kali|sid|trixie' || true

echo "=== binfmt ==="
ls /proc/sys/fs/binfmt_misc/ 2>&1 || true
echo "--- test qemu-aarch64 ---"
# quick test: download a tiny arm64 binary? instead check registered status
cat /proc/sys/fs/binfmt_misc/qemu-aarch64 2>&1 | head -5 || true

echo "=== disk ==="
df -h / | tail -1
echo "=== DONE ==="
