#!/bin/bash
# NIGHTHAWK OS - Phase 3: add Kali rolling repo (arm64) + keyring + apt pinning
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -o pipefail
R=/home/kali/nh-build/rootfs
LOG=/home/kali/nh-build/phase3.log
exec > >(tee -a "$LOG") 2>&1

echo "=== phase3 start $(date -u +%FT%TZ) ==="

# Kali signing key: fetch from Kali's official keyserver (gpg keyring for apt)
echo "[1] fetch Kali archive keyring (arm64)"
mkdir -p "$R/usr/share/keyrings" "$R/etc/apt/keyrings"
curl -fsSL https://archive.kali.org/archive-key.asc -o /tmp/kali-key.asc || { echo "FATAL key download"; exit 1; }
gpg --dearmor < /tmp/kali-key.asc > "$R/etc/apt/keyrings/kali-archive-keyring.gpg" || { echo "FATAL gpg dearmor"; exit 1; }
echo "    installed -> /etc/apt/keyrings/kali-archive-keyring.gpg"

echo "[2] write Kali source list (arm64, kali-rolling, non-free + non-free-firmware)"
cat > "$R/etc/apt/sources.list.d/kali.list" <<'EOF'
# NIGHTHAWK OS - Kali Linux rolling repository (arm64)
# Reused from the source Kali image's package management model.
deb [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF
echo "    wrote /etc/apt/sources.list.d/kali.list"
cat "$R/etc/apt/sources.list.d/kali.list"

echo "[3] write apt pinning (Kali at 500; prefer Debian trixie base for stability, allow Kali for tools)"
cat > "$R/etc/apt/preferences.d/nighthawk" <<'EOF'
# NIGHTHAWK OS - repository compatibility pinning
# Base system is Debian 13 (trixie). Kali rolling is used for security tooling.
# Keep Debian at 990 for core libs/ABI stability; allow Kali at 500 so
# security tools can be pulled from Kali when requested explicitly (-t kali-rolling).
Package: *
Pin: release o=Debian
Pin-Priority: 990

Package: *
Pin: release o=Kali
Pin-Priority: 500

Package: *
Pin: release a=trixie-security
Pin-Priority: 990
EOF
echo "    wrote /etc/apt/preferences.d/nighthawk"

echo "[4] apt-get update in chroot"
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-get update 2>&1 | tail -25 || { echo "FATAL apt-get update"; exit 1; }

echo "[5] verify Kali + Debian + Armbian repos all resolvable"
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-cache policy 2>&1 | grep -Ei 'kali|debian|armbian|release' | head -40

echo "[6] confirm a Kali-only security package is visible (arm64)"
chroot "$R" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  apt-cache policy lynis ufw nmap tcpdump firefox-esr xfce4-session 2>&1 | head -60

echo "=== phase3 done $(date -u +%FT%TZ) ==="
