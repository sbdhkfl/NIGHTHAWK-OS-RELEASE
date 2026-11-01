#!/bin/bash
set -u
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4f.log
exec > >(tee "$LOG") 2>&1
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done

echo "=== apt cache ==="
du -sh "$R/var/cache/apt/archives" 2>/dev/null
echo "=== who depends on gdal/opencv/qt5 ==="
chroot "$R" dpkg-query -W -f='${Package}: ${Depends}\n' 2>/dev/null | grep -E 'libgdal36|libopencv-core410|libqt5core5t64' | grep -v '^libgdal36:\|^libopencv-core410:\|^libqt5core5t64:'
echo "=== manual gdal/opencv/qt ==="
chroot "$R" apt-mark showmanual | grep -E 'gdal|opencv|qt5|heif|poppler' || echo none
echo "=== autoremove ==="
chroot "$R" env DEBIAN_FRONTEND=noninteractive apt-get --purge autoremove -y 2>&1 | tail -8
echo "=== clean ==="
chroot "$R" apt-get clean
rm -rf "$R"/var/cache/apt/archives/*.deb
echo "=== size now ==="
du -shx --exclude=proc --exclude=sys --exclude=dev "$R"
echo "=== done ==="
