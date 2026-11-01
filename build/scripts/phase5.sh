#!/bin/bash
# Phase 5: NIGHTHAWK identity, branding, desktop defaults, services
set -u
R=/home/kali/nh-build/rootfs
SRC=/home/kali/nh-src
LOG=/home/kali/nh-build/phase5.log
exec > >(tee "$LOG") 2>&1
for d in dev dev/pts proc sys; do mountpoint -q "$R/$d" || mount -o bind "/$d" "$R/$d"; done
[ -f "$R/etc/resolv.conf" ] || echo "nameserver 1.1.1.1" > "$R/etc/resolv.conf"

echo "=== identity ==="
echo nighthawk > "$R/etc/hostname"
cat > "$R/etc/hosts" <<'EOF'
127.0.0.1   localhost
127.0.1.1   nighthawk
::1         localhost ip6-localhost ip6-loopback
EOF

cat > "$R/etc/os-release" <<'EOF'
PRETTY_NAME="NIGHTHAWK OS 1.0 (trixie)"
NAME="NIGHTHAWK OS"
VERSION_ID="1.0"
VERSION="1.0 (trixie)"
VERSION_CODENAME=trixie
ID=nighthawk
ID_LIKE=debian
HOME_URL="https://nighthawk-os.invalid/"
ANSI_COLOR="1;31"
LOGO=nighthawk-logo
EOF

cat > "$R/etc/nighthawk-release" <<'EOF'
NIGHTHAWK OS 1.0
Base:      Armbian (Debian 13 trixie) + Kali rolling package channel
Board:     Orange Pi Zero 3 (Allwinner H618, ARM64)
Kernel:    6.18.57-current-sunxi64
Desktop:   XFCE4 (minimal) + LightDM
Toolkit:   nmap, lynis, tcpdump, ufw, dnsutils, python3
EOF

cat > "$R/etc/motd" <<'EOF'

  _  _ ___ ___ _  _ _____ _  _ ___ _  _ _  __
 | \| |_ _/ __| || |_   _| || | __| |/ /| |/ /
 | .` || | (_ | __ | | | | __ | _|| ' < | ' <
 |_|\_|___\___|_||_| |_| |_||_|___|_|\_\|_|\_\

 NIGHTHAWK OS 1.0 - Orange Pi Zero 3 (ARM64)

   Desktop .... XFCE4        Browser ... Firefox ESR
   Toolkit .... nmap, lynis, tcpdump, ufw
   Help ....... nighthawk --help

EOF

echo "/usr/sbin/lightdm" > "$R/etc/X11/default-display-manager"

echo "=== overlay files ==="
mkdir -p "$R/usr/share/backgrounds" "$R/usr/share/themes/Nighthawk/gtk-2.0" \
         "$R/usr/share/themes/Nighthawk/gtk-3.0" "$R/usr/share/icons/NightHawk/apps" \
         "$R/usr/share/applications/nighthawk" "$R/usr/local/bin" \
         "$R/etc/lightdm" "$R/etc/sysctl.d" "$R/etc/ssh/sshd_config.d" \
         "$R/etc/firefox-esr/policies" "$R/usr/lib/firefox-esr/defaults/pref" \
         "$R/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml" \
         "$R/etc/skel/.config/xfce4/terminal" \
         "$R/etc/systemd/system/getty@tty1.service.d"

cp "$SRC/branding/png/nighthawk-wallpaper.png" "$R/usr/share/backgrounds/nighthawk-wallpaper.png"
cp "$SRC/branding/png/nighthawk-logo.png" "$R/usr/share/pixmaps/nighthawk-logo.png" 2>/dev/null || {
  mkdir -p "$R/usr/share/pixmaps"; cp "$SRC/branding/png/nighthawk-logo.png" "$R/usr/share/pixmaps/nighthawk-logo.png"; }
cp "$SRC/branding/icons/apps/"*.svg "$R/usr/share/icons/NightHawk/apps/"
cp "$SRC/branding/icons/index.theme" "$R/usr/share/icons/NightHawk/index.theme"
cp "$SRC/desktop/xfce/theme/gtk-3.0/gtk.css" "$R/usr/share/themes/Nighthawk/gtk-3.0/gtk.css"
cp "$SRC/desktop/xfce/theme/gtk-2.0/gtkrc" "$R/usr/share/themes/Nighthawk/gtk-2.0/gtkrc"
cat > "$R/usr/share/themes/Nighthawk/index.theme" <<'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Nighthawk
Comment=NIGHTHAWK OS crimson dark theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Nighthawk
MetacityTheme=Adwaita
IconTheme=NightHawk
CursorTheme=Adwaita
EOF

cp "$SRC/userpatches/overlay/usr/share/applications/nighthawk/"*.desktop "$R/usr/share/applications/nighthawk/"
cp "$SRC/userpatches/overlay/etc/sysctl.d/99-nighthawk.conf" "$R/etc/sysctl.d/99-nighthawk.conf"
cp "$SRC/userpatches/overlay/etc/ssh/sshd_config.d/99-nighthawk.conf" "$R/etc/ssh/sshd_config.d/99-nighthawk.conf"
cp "$SRC/terminal/profile.d/nighthawk.sh" "$R/etc/profile.d/nighthawk.sh"
cp "$SRC/desktop/lightdm/lightdm.conf" "$R/etc/lightdm/lightdm.conf"
cp "$SRC/browser/firefox/policies.json" "$R/etc/firefox-esr/policies/policies.json"

# SSH: root login and password auth off (key auth only)
grep -q '^PasswordAuthentication' "$R/etc/ssh/sshd_config.d/99-nighthawk.conf" || \
  echo 'PasswordAuthentication no' >> "$R/etc/ssh/sshd_config.d/99-nighthawk.conf"

# Firefox system prefs via autoconfig (user.js -> firefox.cfg)
cat > "$R/usr/lib/firefox-esr/defaults/pref/nighthawk-autoconfig.js" <<'EOF'
// NIGHTHAWK OS - Firefox ESR system preferences bootstrap
pref("general.config.filename", "nighthawk.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF
{ echo '// NIGHTHAWK OS - system preferences (generated from browser/firefox/user.js)'; \
  sed -e 's/^user_pref(/pref(/' "$SRC/browser/firefox/user.js"; } > "$R/usr/lib/firefox-esr/nighthawk.cfg"

echo "=== lightdm greeter ==="
cat > "$R/etc/lightdm/lightdm-gtk-greeter.conf" <<'EOF'
[greeter]
background=/usr/share/backgrounds/nighthawk-wallpaper.png
theme-name=Nighthawk
icon-theme-name=NightHawk
font-name=Sans 10
xft-antialias=true
indicators=~host;~spacer;~clock;~spacer;~session;~power
EOF

echo "=== xfce defaults (skel) ==="
cat > "$R/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/nighthawk-wallpaper.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
cat > "$R/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Nighthawk"/>
    <property name="IconThemeName" type="string" value="NightHawk"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
  </property>
</channel>
EOF
cat > "$R/etc/skel/.config/xfce4/terminal/terminalrc" <<'EOF'
[Configuration]
FontName=Monospace 10
ColorForeground=#e8e8ec
ColorBackground=#0a0a0c
ColorCursor=#e10613
ColorPalette=#0a0a0c;#e10613;#7bd88f;#e1c05a;#5aa9e1;#c46ad6;#5ad6c8;#c8c8d0;#3a3a44;#ff3b47;#9bff8f;#ffd75a;#7bc4ff;#e08bff;#7bffe8;#ffffff
MiscBell=FALSE
MiscConfirmClose=FALSE
MiscAlwaysShowTabs=FALSE
EOF

echo "=== security helper scripts ==="
cp "$SRC/security/scripts/nighthawk-sysinfo.sh" "$R/usr/local/bin/nighthawk-sysinfo"
cp "$SRC/security/scripts/nighthawk-filecheck.sh" "$R/usr/local/bin/nighthawk-filecheck"
cat > "$R/usr/local/bin/nighthawk" <<'EOF'
#!/bin/bash
# NIGHTHAWK OS - helper dispatcher
case "${1:-}" in
  sysinfo)   shift; exec /usr/local/bin/nighthawk-sysinfo "$@" ;;
  filecheck) shift; exec /usr/local/bin/nighthawk-filecheck "$@" ;;
  wifi)      shift; exec nmtui "$@" ;;
  help|-h|--help|"")
    cat <<'TXT'
NIGHTHAWK OS helpers
  nighthawk sysinfo            system + thermal + network summary
  nighthawk filecheck --create /etc/nighthawk-baseline.sha256
  nighthawk filecheck --verify /etc/nighthawk-baseline.sha256
  nighthawk wifi               NetworkManager text UI (nmtui)
  sudo lynis audit system      security audit
TXT
    ;;
  *) echo "unknown command: $1 (try: nighthawk --help)" >&2; exit 2 ;;
esac
EOF
chmod 755 "$R/usr/local/bin/nighthawk" "$R/usr/local/bin/nighthawk-sysinfo" "$R/usr/local/bin/nighthawk-filecheck"
chmod 755 "$R/etc/profile.d/nighthawk.sh"

echo "=== first boot wizard ==="
cp "$SRC/userpatches/firstboot.conf" "$R/root/.not_logged_in_yet"
chmod 600 "$R/root/.not_logged_in_yet"
cat > "$R/etc/systemd/system/getty@tty1.service.d/override.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF

echo "=== services ==="
systemctl --root="$R" enable lightdm.service NetworkManager.service 2>&1 | tail -2
systemctl --root="$R" disable systemd-networkd.service systemd-networkd.socket wpa_supplicant.service 2>&1 | tail -2
if [ -e "$R/usr/lib/systemd/system/zram-generator.service" ]; then
  cp "$SRC/userpatches/overlay/etc/systemd/zram-generator.conf" "$R/etc/systemd/zram-generator.conf"
  systemctl --root="$R" enable systemd-zram-setup@zram0.service 2>&1 | tail -1
elif [ -e "$R/usr/lib/systemd/system/armbian-zram-config.service" ]; then
  systemctl --root="$R" enable armbian-zram-config.service 2>&1 | tail -1
else
  echo "WARN: no zram unit found"
fi

echo "=== identity of ssh keys: regenerate on first boot ==="
rm -f "$R"/etc/ssh/ssh_host_*
echo "=== locales/keyboard ==="
echo 'LANG=en_US.UTF-8' > "$R/etc/default/locale"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\n' > "$R/etc/default/keyboard"

echo "=== verification ==="
for f in etc/os-release etc/motd etc/lightdm/lightdm.conf usr/share/backgrounds/nighthawk-wallpaper.png \
         usr/share/themes/Nighthawk/gtk-3.0/gtk.css usr/local/bin/nighthawk root/.not_logged_in_yet; do
  [ -e "$R/$f" ] && echo "OK      $f" || echo "MISSING $f"
done
echo "=== symlinks enabled ==="
ls "$R/etc/systemd/system/multi-user.target.wants/" | tr '\n' ' '
echo
echo "=== done $(date) ==="
