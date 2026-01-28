# FrutigerLinux Custom ISO Build Guide

This guide shows how to create a custom Debian 13 ISO with FrutigerLinux-WEB-OS pre-installed and auto-updating from GitHub.

## Repository Information
- **GitHub**: https://github.com/BV0073194/FrutigerLinux-WEB-OS
- **Auto-Update**: System checks every 6 hours for updates

## Prerequisites

```bash
sudo apt update
sudo apt install -y live-build git debootstrap squashfs-tools xorriso isolinux syslinux-efi grub-pc-bin grub-efi-amd64-bin mtools
```

## Method 1: Quick Build with live-build (Recommended)

### Step 1: Create Build Directory

```bash
mkdir -p ~/frutiger-iso-build
cd ~/frutiger-iso-build
```

### Step 2: Initialize live-build Configuration

```bash
lb config \
    --distribution trixie \
    --debian-installer live \
    --archive-areas "main contrib non-free non-free-firmware" \
    --apt-recommends true \
    --bootappend-live "boot=live components quiet splash" \
    --linux-flavours amd64 \
    --memtest none \
    --win32-loader false \
    --iso-application "FrutigerLinux Web OS" \
    --iso-publisher "FrutigerLinux Project" \
    --iso-volume "FrutigerLinux-Debian13-$(date +%Y%m%d)"
```

### Step 3: Create Package List

```bash
mkdir -p config/package-lists

cat > config/package-lists/frutiger.list.chroot << 'EOF'
# System essentials
build-essential
curl
wget
git
sudo
ssh

# Desktop environment
xorg
openbox
xinit
chromium
lxdm

# Node.js dependencies (will be added via hook)
# Xpra dependencies
python3
python3-pip

# Flatpak
flatpak

# Networking
net-tools
network-manager

# Utilities
vim
nano
htop
EOF
```

### Step 4: Create Installation Hooks

```bash
mkdir -p config/hooks/normal

# Hook 1: Install Node.js 20.x
cat > config/hooks/normal/0100-install-nodejs.hook.chroot << 'EOF'
#!/bin/bash
set -e
echo "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
EOF
chmod +x config/hooks/normal/0100-install-nodejs.hook.chroot

# Hook 2: Clone FrutigerLinux repository
cat > config/hooks/normal/0200-install-frutiger.hook.chroot << 'EOF'
#!/bin/bash
set -e
echo "Installing FrutigerLinux-WEB-OS..."

# Clone repository to /opt
mkdir -p /opt
cd /opt
git clone https://github.com/BV0073194/FrutigerLinux-WEB-OS

# Install system
cd /opt/FrutigerLinuxWEB-OS
chmod +x setup.sh
chmod +x update-system.sh
chmod +x install-autoupdate.sh

# Create placeholder user directory (will be setup properly on first boot)
mkdir -p /etc/skel/.config/systemd/user
EOF
chmod +x config/hooks/normal/0200-install-frutiger.hook.chroot

# Hook 3: Configure auto-login and startup
cat > config/hooks/normal/0300-configure-autostart.hook.chroot << 'EOF'
#!/bin/bash
set -e
echo "Configuring auto-login and startup..."

# Create default user 'frutiger' with password 'frutiger'
useradd -m -s /bin/bash -G sudo frutiger
echo "frutiger:frutiger" | chpasswd

# Configure LXDM for auto-login
cat > /etc/lxdm/lxdm.conf << 'LXDM'
[base]
autologin=frutiger
session=/usr/bin/openbox-session

[server]
arg=/usr/bin/X -background none

[display]
gtk_theme=Adwaita
bg=/usr/share/backgrounds/desktop-base/default
bottom_pane=1
lang=1
keyboard=1
theme=Industrial
LXDM

# Enable LXDM service
systemctl enable lxdm

# Create first-boot script
cat > /usr/local/bin/frutiger-firstboot.sh << 'FIRSTBOOT'
#!/bin/bash
MARKER="/opt/FrutigerLinuxWEB-OS/.installed"

if [ ! -f "$MARKER" ]; then
    echo "Running FrutigerLinux first-boot setup..."
    
    # Run setup script as user
    cd /opt/FrutigerLinuxWEB-OS
    su - frutiger -c "cd /opt/FrutigerLinuxWEB-OS && ./setup.sh"
    
    # Install auto-update system
    su - frutiger -c "cd /opt/FrutigerLinuxWEB-OS && ./install-autoupdate.sh"
    
    # Mark as installed
    touch "$MARKER"
    
    echo "First-boot setup completed!"
fi
FIRSTBOOT
chmod +x /usr/local/bin/frutiger-firstboot.sh

# Create systemd service for first boot
cat > /etc/systemd/system/frutiger-firstboot.service << 'SERVICE'
[Unit]
Description=FrutigerLinux First Boot Setup
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/opt/FrutigerLinuxWEB-OS/.installed

[Service]
Type=oneshot
ExecStart=/usr/local/bin/frutiger-firstboot.sh
RemainAfterExit=yes
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable frutiger-firstboot.service

# Create .xinitrc for user to auto-start in kiosk mode
cat > /etc/skel/.xinitrc << 'XINITRC'
#!/bin/bash
cd /opt/FrutigerLinuxWEB-OS
exec openbox-session &
exec chromium --kiosk --no-first-run --disable-infobars --disable-session-crashed-bubble --use-gl=swiftshader --disable-gpu --disable-software-rasterizer --force-device-scale-factor=1 http://localhost:3000
XINITRC
chmod +x /etc/skel/.xinitrc
EOF
chmod +x config/hooks/normal/0300-configure-autostart.hook.chroot
```

### Step 5: Build the ISO

```bash
sudo lb build 2>&1 | tee build.log
```

This will take 30-60 minutes depending on your internet speed and system.

### Step 6: Get Your ISO

```bash
ls -lh *.iso
# Output: FrutigerLinux-Debian13-YYYYMMDD.hybrid.iso
```

## Method 2: Using Existing Debian Installation (Faster)

If you already have a working Debian 13 system with FrutigerLinux installed:

### Step 1: Install SystemBack

```bash
sudo apt install -y systemback
```

### Step 2: Create Live ISO

1. Launch SystemBack: `sudo systemback`
2. Click **"Live system create"**
3. Enter name: `FrutigerLinux-Debian13`
4. Click **"Create new"**
5. Wait for ISO creation (10-20 minutes)
6. ISO will be saved to `/home` directory

## VMware Testing Configuration

### Recommended VM Settings:
- **Memory**: 4 GB minimum (8 GB recommended)
- **Processors**: 2 cores minimum
- **Hard Disk**: 25 GB minimum (50 GB recommended)
- **Display**: 3D Graphics Acceleration enabled
- **Network**: NAT or Bridged

### Installation Steps:

1. Boot from ISO in VMware
2. Select **"Live system (amd64)"** from boot menu
3. System will auto-login as user `frutiger` (password: `frutiger`)
4. First boot setup runs automatically (~5-10 minutes)
5. Browser opens automatically in kiosk mode
6. **One-time Moonlight pairing**: Open terminal and visit http://localhost:47990

### After Installation:

The system will automatically:
- Check for updates every 6 hours from GitHub
- Pull latest code from https://github.com/BV0073194/FrutigerLinux-WEB-OS
- Restart services if needed
- Log updates to `/var/log/frutiger-update.log`

### Manual Update Check:

```bash
sudo /opt/FrutigerLinuxWEB-OS/update-system.sh
```

### View Update Logs:

```bash
# Recent updates
journalctl --user -u frutiger-update.service -n 50

# Full log
tail -f /var/log/frutiger-update.log
```

## Troubleshooting

### ISO Build Fails:

```bash
# Clean and retry
sudo lb clean --purge
sudo lb config [your options]
sudo lb build
```

### Update System Not Working:

```bash
# Check timer status
systemctl --user status frutiger-update.timer

# Check service status
systemctl --user status frutiger-update.service

# View logs
journalctl --user -u frutiger-update.service

# Restart timer
systemctl --user restart frutiger-update.timer
```

### Services Not Starting:

```bash
# Check Xpra
systemctl --user status xpra.service

# Check Sunshine
systemctl --user status sunshine.service

# Check Node.js server
cd /opt/FrutigerLinuxWEB-OS/server
npm start
```

## Distribution

### Share as ISO:
- Upload `FrutigerLinux-Debian13-YYYYMMDD.hybrid.iso` to file hosting
- Bootable on USB drives (use Rufus/Etcher/dd)

### Share as VMware Template:
```bash
# Export as OVA
# In VMware: File → Export to OVF
# Share the .ova file
```

### GitHub Releases:
Create releases on your GitHub repository with ISO files attached for easy distribution.

## Update Frequency

By default, the system checks for updates:
- **5 minutes after boot**
- **Every 6 hours** thereafter

To change frequency, edit `/home/frutiger/.config/systemd/user/frutiger-update.timer`:

```ini
# For hourly updates:
OnUnitActiveSec=1h

# For daily updates:
OnUnitActiveSec=24h

# Then reload:
systemctl --user daemon-reload
systemctl --user restart frutiger-update.timer
```

## Security Notes

- Default user: `frutiger` / password: `frutiger` (CHANGE THIS!)
- Auto-update runs without confirmation (trusted repository)
- Update script logs all changes to `/var/log/frutiger-update.log`
- Services restart automatically after updates

## Support

- GitHub Issues: https://github.com/BV0073194/FrutigerLinux-WEB-OS/issues
- View logs: `/var/log/frutiger-update.log`
- Check services: `systemctl --user list-units | grep frutiger`
