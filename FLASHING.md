# Flashing NIGHTHAWK OS to microSD

You need:

- The compressed NIGHTHAWK OS release archive (download it from the release **Assets** section)
- A microSD card, **8 GB minimum** (16 GB recommended), Class 10 / A1+
- A card reader
- Optional: HDMI cable, USB keyboard, 5 V / 3 A USB-C power supply

> **Important:** Download the compressed archive, extract it, and flash the
> resulting `nighthawk-os-1.0-orangepi-zero3-arm64.img` file. Do not select
> the compressed archive in balenaEtcher or another flashing program.

## 1. Download and extract the image

1. Open the [NIGHTHAWK OS 1.0 Releases page](https://github.com/sbdhkfl/NIGHTHAWK-OS-RELEASE/releases).
2. Under the latest compatible release, find **Assets** and download the image archive.
3. Extract the archive:
   - **Windows:** Right-click the downloaded archive and choose **7-Zip → Extract Here** or **Extract to...**. If Windows does not show an extraction option, install [7-Zip](https://www.7-zip.org/).
   - **macOS:** Double-click a `.zip` or `.gz` archive. For a `.7z` archive, use an archive utility that supports 7z.
   - **Linux:** Use your file manager's **Extract** option, or use the matching command:
     - `.zip`: `unzip archive-name.zip`
     - `.7z`: `7z x archive-name.7z`
     - `.gz`: `gzip -dk archive-name.img.gz`
4. Confirm that the extracted file is named
   `nighthawk-os-1.0-orangepi-zero3-arm64.img`.

If the archive contains a folder, open it and locate the `.img` file inside.
Keep the extracted image; this is the file you will flash.

## 2. Verify the extracted image

Verify the **extracted .img file**, not the compressed archive.

Expected SHA256:

```text
126312ebe591737c114bf8b420f55bc0def6838de5588182ee515ffc77d26885
```

Windows PowerShell:

```powershell
Get-FileHash .\\nighthawk-os-1.0-orangepi-zero3-arm64.img -Algorithm SHA256
```

Linux:

```bash
sha256sum nighthawk-os-1.0-orangepi-zero3-arm64.img
```

macOS:

```bash
shasum -a 256 nighthawk-os-1.0-orangepi-zero3-arm64.img
```

Compare the result with the expected SHA256 above. Do not flash the image if
the checksum does not match; download the archive again.

## 3. Write the image

### Option A — balenaEtcher (Windows/macOS/Linux, easiest)

1. Open balenaEtcher.
2. Select the **extracted `.img` file** (not the `.zip`, `.7z`, or `.gz` archive).
3. Select the microSD card (**double-check the drive**).
4. Flash, then let it verify.

### Option B — Raspberry Pi Imager

Choose OS → Use custom → select the **extracted `.img` file** → select the card → Write.

### Option C — `dd` (Linux/macOS)

```bash
lsblk                     # identify the card, e.g. /dev/sdX (NOT /dev/sdX1)
sudo umount /dev/sdX* 2>/dev/null
sudo dd if=nighthawk-os-1.0-orangepi-zero3-arm64.img of=/dev/sdX bs=4M \\
     status=progress conv=fsync
sync
```

On macOS: use `/dev/rdiskN` instead of `/dev/diskN`.

### Option D — Windows (no extra tools)

Use balenaEtcher or Raspberry Pi Imager. File Explorer's copy command will
not write a bootable disk image to the card.

## 4. First boot

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

## 5. After first boot

```bash
sudo apt update && sudo apt upgrade      # refresh from Debian + Kali
sudo ufw allow ssh && sudo ufw enable    # firewall is installed but off by default
nighthawk sysinfo                        # system, thermal and network summary
```

Optional Kali tooling, pulled from the pinned Kali channel:

```bash
sudo apt install -t kali-rolling <package>
```

## 6. Re-flashing

Re-flash the same extracted image at any time; the card is fully overwritten.
Keep the original extracted `.img` and its checksum.

## Card size note

The image is 1.77 GB, so any card of 8 GB or more works. Free space is only
visible after first boot, when the partition is grown to fill the card.
