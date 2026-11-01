#!/bin/bash
L=/home/kali/nh-build/phase4e.log
tail -4 "$L" 2>/dev/null
echo "--- dpkg procs: $(pgrep -c -f 'dpkg|apt-get' 2>/dev/null || echo 0)"
echo "--- last dpkg.log:"
tail -2 /home/kali/nh-build/rootfs/var/log/dpkg.log 2>/dev/null
