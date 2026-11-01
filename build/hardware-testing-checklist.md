# Physical hardware test checklist — NIGHTHAWK OS 1.0

Nothing here was executed during the build: no Orange Pi Zero 3 board was
available. These are the checks to run on real hardware, in order.

Image: `nighthawk-os-1.0-orangepi-zero3-arm64.img`
SHA256: `126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885`

## Pre-test

- [ ] `sha256sum -c SHA256SUMS` passes on the host.
- [ ] Image written with Etcher / RPi Imager / `dd` and verified by the tool.
- [ ] microSD ≥ 8 GB, known-good (test with `f3` or `h2testw`).
- [ ] 5 V / 3 A supply, known-good cable.
- [ ] HDMI monitor + micro-HDMI adapter, USB keyboard, Ethernet cable.

## Boot

- [ ] Serial console at 115200 8N1 shows U-Boot, then kernel.
- [ ] HDMI output appears within 2–3 minutes of first boot.
- [ ] `armbian-resize-filesystem` ran: `df -h /` shows the full card size.
- [ ] First-login wizard appears on the console (`tty1`).
- [ ] Wizard completes: new root password set, user created.
- [ ] Auto-login override removed after wizard; console returns to a login prompt.
- [ ] LightDM greeter appears with the NIGHTHAWK wallpaper and theme.

## Desktop

- [ ] Login as the created user, XFCE session starts (< 10 s on 2 GB).
- [ ] Wallpaper, GTK theme, icon theme, terminal palette all NIGHTHAWK-styled.
- [ ] `nighthawk sysinfo` prints model, kernel, RAM, thermal, listening ports.
- [ ] `free -h` shows zram0 as swap (`zramctl` lists it).
- [ ] Firefox ESR launches, opens `about:blank`, no autoconfig error.
- [ ] Thunar opens, terminal opens, panel applets load, logout/reboot work.

## Networking

- [ ] Ethernet: link up, DHCP address, `ping 1.1.1.1`, DNS resolves.
- [ ] Wi-Fi scan finds networks (`nmtui`), association works, DHCP works.
- [ ] Reboot with Wi-Fi configured: connection re-establishes automatically.
- [ ] `nm-applet` shows connectivity in the panel.
- [ ] SSH from another host with a public key works; password login is refused.
- [ ] `sudo systemctl status NetworkManager` is active; `systemd-networkd` is not.

## Hardware

- [ ] USB 2.0 ports: keyboard, mouse, mass storage.
- [ ] Bluetooth: `bluetoothctl` scan finds a device, pairing works.
- [ ] Thermal: `cat /sys/class/thermal/thermal_zone0/temp` under `stress-ng --cpu 4`.
- [ ] No undervoltage warnings in `dmesg`; no random reboots over a 1 hour run.
- [ ] Audio over HDMI (if the use case needs it).
- [ ] Reboot 3x: filesystem clean (`fsck -f` on a reader shows no errors).
- [ ] 4 GB variant: same image boots, `free -h` shows ~4 GB, zram sized `ram/4`.

## Post-test (send back)

```bash
nighthawk sysinfo > /tmp/nh-report.txt
dmesg >> /tmp/nh-report.txt
journalctl -b --no-pager >> /tmp/nh-report.txt
```

Mark each failure with the exact command output; Wi-Fi/BT issues need
`dmesg | grep -i -E 'uwe|sprd|blue'` and `rfkill list`.
