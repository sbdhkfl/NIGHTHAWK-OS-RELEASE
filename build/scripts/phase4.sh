#!/bin/bash
# NIGHTHAWK OS - Phase 4: install desktop + security toolkit into arm64 chroot
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase4.log
exec > >(tee -a "$LOG") 2>&1

echo "=== phase4 start $(date -u +%FT%TZ) ==="

chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root DEBIAN_FRONTEND=noninteractive LC_ALL=C bash -s <<'CHROOT'
set -o pipefail
echo "[A] base upgrade (keep it minimal — no recommends anywhere)"
apt-get install -y --no-install-recommends \
  locales console-setup sudo ca-certificates 2>&1 | tail -6

echo "[B] NIGHTHAWK 10-core + 40-security-core (authoritative pkg-lists, deduped)"
apt-get install -y --no-install-recommends \
  curl wget git python3 python3-venv dnsutils openssh-client \
  lynis ufw nmap tcpdump openssh-server 2>&1 | tail -12

echo "[C] NIGHTHAWK 20-desktop (XFCE minimal + LightDM)"
apt-get install -y --no-install-recommends \
  xfce4-session xfce4-panel xfce4-settings xfce4-terminal thunar \
  xfce4-appfinder xfwm4 xfdesktop xfce4-power-manager xfce4-screenshooter \
  xfce4-clipman-plugin btop \
  lightdm lightdm-gtk-greeter polkitd xserver-xorg-core \
  network-manager 2>&1 | tail -20

echo "[D] NIGHTHAWK 30-browser (Firefox ESR)"
apt-get install -y --no-install-recommends firefox-esr 2>&1 | tail -10

echo "[E] generated locale (en_US.UTF-8)"
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen en_US.UTF-8 2>&1 | tail -4
update-locale LANG=en_US.UTF-8 2>/dev/null || true

echo "[F] clean apt caches to stay under 2GB"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[G] package count + disk usage"
dpkg -l | grep -c '^ii'
df -h / | tail -1
du -sm / 2>/dev/null | cut -f1 | xargs -I{} echo "rootfs={}MB"
echo "[H] verify key binaries exist"
for b in lightdm startxfce4 firefox-esr nmap ufw lynis thunar xfce4-terminal NetworkManager; do
  p=$(command -v "$b" 2>/dev/null || echo "MISSING")
  printf '  %-18s %s\n' "$b" "$p"
done
CHROOT

echo "=== phase4 done $(date -u +%FT%TZ) ==="
