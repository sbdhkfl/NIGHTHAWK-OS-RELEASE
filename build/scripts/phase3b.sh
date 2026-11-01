#!/bin/bash
# NIGHTHAWK OS - Phase 3b: verify Kali repo is live for arm64 + test -t kali-rolling
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
R=/home/kali/nh-build/rootfs
A="chroot $R /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root"

echo "=== Kali apt-cache policy (grep kali) ==="
$A apt-cache policy 2>&1 | grep -iE 'kali' | head -20
echo "=== raw sources (what apt sees) ==="
$A apt-get indextargets --format '$(SITE) $(RELEASE) $(COMPONENT) $(ARCHITECTURE)' 2>&1 | grep -iE 'kali|armbian' | head -20
echo "=== a Kali-only tool from kali-rolling: ncat / seclists? pick 'whatweb' (Kali-only) ==="
$A apt-cache policy whatweb 2>&1 | head -12
echo "=== kali-rolling explicit target availability ==="
$A apt-get install -s -t kali-rolling nmap 2>&1 | grep -E 'Inst|Conf|E:|nmap' | head -12
echo "=== verify Kali arm64 Packages index exists on mirror ==="
curl -fsSI http://http.kali.org/dists/kali-rolling/main/binary-arm64/Packages.gz 2>&1 | head -6
echo "=== DONE ==="
