#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "=== URL tests ==="
for u in \
  "https://dl.armbian.com/orangepizero3/Trixie_current_minimal" \
  "https://dl.armbian.com/orangepizero3/Trixie_current_minimal.img.xz" \
  "https://github.com/armbian/community/releases/download/26.11.0-trunk.108/Armbian_community_26.11.0-trunk.108_Orangepizero3_trixie_current_6.18.57_minimal.img.xz"
do
  echo "--- $u"
  timeout 30 wget -q --spider --server-response --max-redirect=8 "$u" 2>&1 | grep -E 'HTTP/|Content-Length|Location' | tail -6
done
echo "=== DONE ==="
