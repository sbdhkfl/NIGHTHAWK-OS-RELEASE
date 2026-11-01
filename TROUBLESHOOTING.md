# Troubleshooting — NIGHTHAWK OS 1.0

Start here: **almost every "it boots then dies" report on Orange Pi Zero 3 is
power or SD-card related.** Use a 5 V / 3 A supply and a genuine Class 10 card.

## No HDMI output

1. Wait 2–3 minutes: the first boot resizes the rootfs before the display
   manager starts.
2. Try another HDMI cable/adapter — the Zero 3 has **micro-HDMI**.
3. Check the serial console (below). If U-Boot prints and the kernel starts,
   the image is fine and the problem is display-side.
4. Try a different monitor; some capture cheap micro-HDMI adapters poorly.
5. Kernel command line can force a mode via `/boot/armbianEnv.txt`
   (`extraargs=video=HDMI-A-1:1280x720@60`), then reboot.

## Serial console (best debugging tool)

Connect a 3.3 V USB-UART adapter to the board's UART header
(GND, TX, RX — **do not connect VCC**), then:

```bash
picocom -b 115200 /dev/ttyUSB0      # or: screen /dev/ttyUSB0 115200
```

You should see U-Boot, then the kernel log. Drop to U-Boot with a keypress
during the countdown to inspect `printenv`.

## It boots but LightDM/XFCE does not start

At the console (Ctrl+Alt+F2 or serial):

```bash
systemctl status lightdm
journalctl -u lightdm -b --no-pager | tail -50
ls /usr/share/xsessions/            # expect xfce.desktop
```

Common causes:

- **Out of memory** on 2 GB with Firefox + heavy tools: close tabs, or check
  `free -h` and `zramctl`. zram swap should be active.
- **Failed session**: log in on a text console and run `startxfce4` to see the
  real error.
- If you previously changed the theme and XFCE now aborts, move the user config
  aside: `mv ~/.config/xfce4 ~/.config/xfce4.bak` and log in again.

## No Wi-Fi

```bash
rfkill list
ip link                        # expect wlan0
dmesg | grep -i -E 'uwe|sprd|wlan'
systemctl status aw859a-wifi
sudo modprobe sprdwl_ng
nmtui
```

- Firmware for the UWE5622 is intentionally trimmed to the files this board
  needs; if `dmesg` reports a missing firmware file, reinstall it with
  `sudo apt install --reinstall armbian-firmware` (adds ~490 MB).
- Wi-Fi country code: `sudo iw reg set <CC>`; NetworkManager may need the
  regulatory domain set in the connection profile.
- Ethernet always works as a fallback: plug in and check `ip a`.

## No Bluetooth

```bash
systemctl status aw859a-bluetooth
sudo systemctl restart bluetooth
bluetoothctl
```

Bluetooth shares the UWE5622 chip with Wi-Fi; if Wi-Fi is up but BT is not,
check `dmesg | grep -i blue` and that the `wcnmodem.bin` firmware is present in
`/lib/firmware/`.

## Filesystem errors / "unexpected inconsistency"

```bash
sudo touch /forcefsck && sudo reboot     # one-shot check on next boot
```

If the card will not boot at all, put it in a card reader on another Linux box:

```bash
sudo fsck -f /dev/sdX1
```

## Root filesystem did not grow to the card size

```bash
df -h /
sudo systemctl status armbian-resize-filesystem
sudo armbian-resize-filesystem       # retry manually
```

## SD card is full sooner than expected

The shipped image is 1.77 GB but the rootfs is ~1.4 GB with ~200 MB free
before the first-boot resize. If resizing failed, the card still works but has
little headroom — re-run the resize command above.

## Forgot the password / locked out

- The console auto-login wizard only exists before the first successful setup.
- Otherwise: mount the SD card's ext4 partition on another Linux machine and
  clear the root password hash in `/etc/shadow`, or boot the board with a USB
  keyboard and use a rescue entry.
- SSH is key-only by design; there is no password login to recover.

## `apt update` fails

```bash
ping -c1 http.kali.org
sudo apt update
```

- If DNS fails: `cat /etc/resolv.conf` (should point at a reachable resolver;
  NetworkManager rewrites it once a connection is up).
- If Kali returns 404 for an old package, that is normal Kali rolling drift —
  `sudo apt full-upgrade` to resync.
- Repo key errors: `sudo apt install --reinstall kali-archive-keyring`.

## Firefox starts with a blank/broken page or refuses to start

```bash
firefox-esr -safe-mode
```

System prefs live in `/usr/lib/firefox-esr/nighthawk.cfg` (via
`defaults/pref/nighthawk-autoconfig.js`). To rule them out temporarily:

```bash
sudo mv /usr/lib/firefox-esr/defaults/pref/nighthawk-autoconfig.js /root/
```

## "It works in the VM but not on the board"

The image cannot run in VirtualBox: it is ARM64 with an Allwinner bootloader.
The Kali VirtualBox image you may have started from is x86_64 and cannot be
booted on this board at all. See `BUILD-REPORT.md` for why this build uses the
Armbian boot chain.

## Collecting a useful bug report

```bash
nighthawk sysinfo > /tmp/report.txt
dmesg >> /tmp/report.txt
journalctl -b --no-pager >> /tmp/report.txt
```
