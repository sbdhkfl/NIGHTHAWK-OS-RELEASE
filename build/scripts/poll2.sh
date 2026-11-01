#!/bin/bash
echo "=== procs ==="
ps -eo pid,etime,stat,cmd | grep -E "apt-get|dpkg|http" | grep -v grep | head
echo "=== dpkg.log tail ==="
tail -3 /home/kali/nh-build/rootfs/var/log/dpkg.log
echo "=== archives count ==="
ls /home/kali/nh-build/rootfs/var/cache/apt/archives/*.deb 2>/dev/null | wc -l
du -sh /home/kali/nh-build/rootfs/var/cache/apt/archives 2>/dev/null
echo "=== last log lines ==="
tail -2 /home/kali/nh-build/phase4g.log | cat -A | cut -c1-200
echo "=== disk ==="
df -h /home/kali | tail -1
