#!/bin/bash
# Phase 5b: size trim + final tidy
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase5b.log
exec > >(tee "$LOG") 2>&1

echo "=== before: $(du -sbx --exclude=proc --exclude=sys --exclude=dev "$R" | cut -f1) bytes ==="

rm -rf "$R"/var/lib/apt/lists/*
mkdir -p "$R/var/lib/apt/lists/partial"

cd "$R/usr/share/locale" && ls | grep -vE '^(en($|_|@)|locale\.alias$)' | xargs -r rm -rf

find "$R/usr/share/doc" -mindepth 1 -maxdepth 1 -type d -print0 |
  while IFS= read -r -d '' d; do find "$d" -mindepth 1 ! -name copyright -delete; done
find "$R/usr/share/doc" -mindepth 1 -maxdepth 1 -type f ! -name copyright -delete

find "$R" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf "$R"/var/log/apt/* "$R"/var/log/journal/* "$R"/tmp/* 2>/dev/null
: > "$R/var/log/dpkg.log"; : > "$R/var/log/alternatives.log"
rm -f "$R"/var/backups/*.gz 2>/dev/null

chroot "$R" apt-get clean 2>/dev/null

echo "=== after: $(du -sbx --exclude=proc --exclude=sys --exclude=dev "$R" | cut -f1) bytes ==="
echo "=== top dirs ==="
du -shx "$R"/usr "$R"/var "$R"/etc "$R"/boot
echo "=== done ==="
