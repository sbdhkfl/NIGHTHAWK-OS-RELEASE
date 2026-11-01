# Flashing NIGHTHAWK OS to microSD

You need:

- `nighthawk-os-1.0-orangepi-zero3-arm64.img` (1.77 GB)
- A microSD card, **8 GB minimum** (16 GB recommended), Class 10 / A1+
- A card reader
- Optional: HDMI cable, USB keyboard, 5 V / 3 A USB-C power supply

The disk image is not stored in this GitHub repository because it exceeds
GitHub's 100 MB file limit. Obtain or rebuild the image before following these
steps.

> The image is a raw disk image. Do **not** copy the file onto a mounted
> filesystem and do **not** extract it. Write it to the *device*.

## 1. Verify the download

```bash
sha256sum nighthawk-os-1.0-orangepi-zero3-arm64.img
# expected: 126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885
```

Windows PowerShell:

```powershell
Get-FileHash .\nighthawk-os-1.0-orangepi-zero3-arm64.img -Algorithm SHA256
```

## 2. Write the image

### Option A — balenaEtcher (Windows/macOS/Linux, easiest)

1. Select the `.img` file.
2. Select the microSD card (**double-check the drive letter**).
3. Flash, then let it verify.

### Option B — Raspberry Pi Imager

"Choose OS" → "Use custom" → pick the `.img` → select the card → Write.

### Option C — `dd` (Linux/macOS)

```bash
lsblk                     # identify the card, e.g. /dev/sdX (NOT /dev/sdX1)
sudo umount /dev/sdX* 2>/dev/null
sudo dd if=nighthawk-os-1.0-orangepi-zero3-arm64.img of=/dev/sdX bs=4M \
     status=progress conv=fsync
sync
```

On macOS: use `/dev/rdiskN` instead of `/dev/diskN`.

### Option D — Windows (no extra tools)

`dd`-style writing needs Etcher/Imager; `copy` and Explorer will not work.

## 3. First boot

1. Insert the card into the Orange Pi Zero 3.
2. Connect HDMI and USB keyboard (recommended), and Ethernet if available.
3. Power on with a 5 V / 3 A supply. First boot takes 1–3 minutes: the
   filesystem is expanded to the card size, then the console shows the
   **NIGHTHAWK / Armbian first-login wizard**.
4. In the wizard:
   - set a new **root** password,
   - create your **user** account (this replaces the generic defaults),
   - optionally set the timezone.
5. Log in at the LightDM greeter with that user.
6. Join Wi-Fi with the tray applet or `nmtui` in a terminal.

> The console auto-logs in as root **only until the wizard completes**, so the
> process can run without a password. Once you finish it, the auto-login
> override is removed and normal logins apply.

## 4. After first boot

```bash
sudo apt update && sudo apt upgrade      # refresh from Debian + Kali
sudo ufw allow ssh && sudo ufw enable    # firewall is installed but off by default
nighthawk sysinfo                        # system, thermal and network summary
```

Optional Kali tooling, pulled from the pinned Kali channel:

```bash
sudo apt install -t kali-rolling <package>
```

## 5. Re-flashing

Re-flash the same image at any time; the card is fully overwritten. Keep the
original `.img` and its checksum — nothing on the card is needed to rebuild.

## Card size note

The image is 1.77 GB, so any card of 8 GB or more works. Free space is only
visible after first boot, when the partition is grown to fill the card.
