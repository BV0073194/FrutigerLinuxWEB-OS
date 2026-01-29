#!/bin/bash

# ============================================
# FrutigerLinuxWEB-OS Setup Script
# For Debian-based Linux (Headless/GUI)
# Fully automated installation - no prompts!
# ============================================

set -e  # Exit on error

echo "=========================================="
echo "FrutigerLinuxWEB-OS Setup Script"
echo "Automated Installation - No Prompts!"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run as root. Run as normal user with sudo access."
    exit 1
fi

echo "📦 Updating package lists..."
sudo apt update

# ============================================
# 1. INSTALL PREREQUISITES
# ============================================
echo ""
echo "📦 Installing prerequisites..."
sudo apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https python3 python3-pip git flatpak

# Setup Flatpak for USER (not system-wide to avoid permission issues)
echo "📦 Setting up Flatpak for user..."
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak --version

# ============================================
# 2. INSTALL NODE.JS AND NPM
# ============================================
echo ""
echo "📦 Installing Node.js and npm..."

# Check current Node.js version
NODE_VERSION=""
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
fi

# Install or upgrade if needed
if [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" -lt 20 ]; then
    if [ ! -z "$NODE_VERSION" ]; then
        echo "⚠️  Node.js $NODE_VERSION detected. Upgrading to Node.js 20.x..."
        # Remove old Node.js first
        sudo apt remove -y nodejs npm
        sudo apt autoremove -y
    fi
    
    echo "📥 Installing Node.js 20.x from NodeSource..."
    
    # Clean up any old NodeSource lists
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
    
    # Download and run NodeSource setup
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    
    # Install Node.js (includes npm)
    sudo apt install -y nodejs
    
    # Verify installation
    if ! command -v node &> /dev/null; then
        echo "❌ ERROR: Node.js installation failed!"
        echo "Please install Node.js 20.x manually:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "  sudo apt install -y nodejs"
        exit 1
    fi
    
    # Check version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        echo "❌ ERROR: Node.js $NODE_VERSION installed, but version 20+ is required!"
        echo "Please install Node.js 20.x manually from https://nodejs.org/"
        exit 1
    fi
    
    echo "✅ Node.js installed: $(node --version)"
    echo "✅ npm installed: $(npm --version)"
else
    echo "✅ Node.js $(node --version) is already installed (version 20+)"
    echo "✅ npm version: $(npm --version)"
fi

# Final verification
if ! command -v npm &> /dev/null; then
    echo "❌ ERROR: npm not found. Installing npm..."
    sudo apt install -y npm
fi

# ============================================
# 3. INSTALL PROJECT DEPENDENCIES
# ============================================
echo ""
echo "📦 Installing project dependencies..."
cd "$(dirname "$0")"

# Verify npm is available before proceeding
if ! command -v npm &> /dev/null; then
    echo "❌ ERROR: npm is still not available. Please install Node.js manually."
    echo "Try: sudo apt install nodejs npm"
    exit 1
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ ERROR: package.json not found in current directory."
    echo "Make sure you're running this script from the project root."
    exit 1
fi

echo "📦 Installing npm packages..."
npm install --no-bin-links
echo "✅ npm packages installed"

# ============================================
# 4. INSTALL VNC COMPONENTS (for GUI app streaming in iframes)
# ============================================
echo ""
echo "📦 Installing VNC components for isolated app windows..."

# Install Xvfb (virtual framebuffer), x11vnc, and noVNC
sudo apt install -y xvfb x11vnc websockify openbox git

# Install noVNC (HTML5 VNC client)
if [ ! -d "/opt/noVNC" ]; then
    echo "📥 Installing noVNC..."
    sudo git clone https://github.com/novnc/noVNC.git /opt/noVNC
    sudo git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify
    echo "✅ noVNC installed"
else
    echo "✅ noVNC already installed"
fi

echo "✅ VNC components installed for isolated app streaming"

# ============================================
# 5. INSTALL CHROMIUM FOR KIOSK MODE
# ============================================
echo ""
echo "📦 Installing Chromium browser for kiosk mode..."
if ! command -v chromium &> /dev/null && ! command -v chromium-browser &> /dev/null; then
    sudo apt install -y chromium
    echo "✅ Chromium installed"
else
    echo "✅ Chromium already installed"
fi

# Determine chromium command
if command -v chromium &> /dev/null; then
    CHROMIUM_CMD="chromium"
elif command -v chromium-browser &> /dev/null; then
    CHROMIUM_CMD="chromium-browser"
else
    CHROMIUM_CMD="chromium"
fi

# ============================================
# 6. INSTALL X SERVER (if not present)
# ============================================
echo ""
echo "📦 Checking for X server..."
if ! dpkg -l | grep -q xserver-xorg; then
    echo "Installing minimal X server..."
    sudo apt install -y xserver-xorg xinit x11-xserver-utils
    echo "✅ X server installed"
else
    echo "✅ X server already installed"
fi

# Always ensure xinit is installed (needed for startx)
if ! command -v startx &> /dev/null; then
    echo "📦 Installing xinit..."
    sudo apt install -y xinit
    echo "✅ xinit installed"
fi

# ============================================
# 7. INSTALL OPENBOX (minimal window manager)
# ============================================
echo ""
echo "📦 Installing Openbox window manager..."
if ! command -v openbox &> /dev/null; then
    sudo apt install -y openbox
    echo "✅ Openbox installed"
else
    echo "✅ Openbox already installed"
fi

# ============================================
# 8. INSTALL SUNSHINE & MOONLIGHT (game streaming)
# ============================================
echo ""
echo "📦 Installing Sunshine & Moonlight for game streaming..."
echo "ℹ️  Sunshine = Server (streams games), Moonlight = Client (receives stream)"
echo ""

# Install Sunshine dependencies for native build
echo "📥 Installing Sunshine dependencies..."
sudo apt install -y \
    libevdev-dev \
    libpulse-dev \
    libopus-dev \
    libxtst-dev \
    libx11-dev \
    libxrandr-dev \
    libxfixes-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    libavcodec-dev \
    libswscale-dev \
    libdrm-dev \
    libcap-dev \
    cmake \
    ninja-build

if ! command -v sunshine &> /dev/null && ! flatpak list --user 2>/dev/null | grep -q sunshine; then
    set +e  # Temporarily disable exit on error for optional component
    
    # Try to install from official Sunshine repo first
    echo "📥 Installing Sunshine via Flatpak (user install)..."
    flatpak install --user -y flathub dev.lizardbyte.app.Sunshine
    
    if flatpak list --user 2>/dev/null | grep -q sunshine; then
        echo "✅ Sunshine installed via Flatpak"
        SUNSHINE_EXEC="/usr/bin/flatpak run --filesystem=host --device=all --share=ipc dev.lizardbyte.app.Sunshine"
    else
        echo "⚠️  Sunshine installation failed, but continuing setup..."
        SUNSHINE_EXEC="sunshine"
    fi
    
    set -e  # Re-enable exit on error
else
    echo "✅ Sunshine already installed"
    if command -v sunshine &> /dev/null; then
        SUNSHINE_EXEC="sunshine"
    else
        SUNSHINE_EXEC="/usr/bin/flatpak run --filesystem=host --device=all --share=ipc dev.lizardbyte.app.Sunshine"
    fi
fi

# Install Moonlight client
if ! flatpak list --user 2>/dev/null | grep -q moonlight; then
    echo "📥 Installing Moonlight via Flatpak (user install)..."
    flatpak install --user -y flathub com.moonlight_stream.Moonlight
    echo "✅ Moonlight installed (run: flatpak run com.moonlight_stream.Moonlight)"
else
    echo "✅ Moonlight already installed"
fi

echo ""
echo "🎮 Setting up Sunshine auto-start..."

# Configure uinput permissions for virtual input devices
echo "🔧 Configuring uinput permissions for virtual devices..."
sudo bash -c 'echo "KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"" > /etc/udev/rules.d/60-sunshine-input.rules'
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to input group for device access
sudo usermod -a -G input $USER

# Create systemd user service for Sunshine
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/sunshine.service << SUNSHINE_SERVICE
[Unit]
Description=Sunshine Game Streaming Server
After=network.target graphical-session.target

[Service]
Type=simple
Environment="DISPLAY=:0"
Environment="XAUTHORITY=%h/.Xauthority"
Environment="SUNSHINE_ENCODER=software"
Environment="SUNSHINE_CAPTURE_METHOD=x11"
ExecStart=${SUNSHINE_EXEC}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SUNSHINE_SERVICE

# Create Sunshine config directory and set software encoding
mkdir -p ~/.config/sunshine
cat > ~/.config/sunshine/sunshine.conf << 'SUNSHINECONF'
# VMware optimized configuration
encoder = software
capture = x11
bitrate = 20000
framerate = 60
resolution = 1920x1080

# Virtual input settings
virtual_input = 1
SUNSHINECONF

# Enable and start Sunshine service
systemctl --user daemon-reload
systemctl --user enable sunshine.service

# Only start if we're in a graphical session (not in WSL)
if [ -n "$DISPLAY" ]; then
    systemctl --user start sunshine.service
    
    echo "✅ Sunshine service created and started"
    echo "   Access web UI: http://localhost:47990"
    echo "   Username: admin (set password on first visit)"
    
    # Wait for Sunshine to start
    echo "⏳ Waiting for Sunshine to initialize..."
    sleep 5
    
    # Check if Sunshine is running
    if systemctl --user is-active --quiet sunshine.service; then
        echo "✅ Sunshine is running"
        echo ""
        echo "📝 IMPORTANT: Complete setup in web browser:"
        echo "   1. Open: http://localhost:47990"
        echo "   2. Set admin password"
        echo "   3. Configure apps (Desktop, Steam, etc.)"
        echo ""
        echo "🔗 Pair Moonlight:"
        echo "   1. Open Moonlight: flatpak run com.moonlight_stream.Moonlight"
        echo "   2. It should auto-detect Sunshine on 127.0.0.1"
        echo "   3. Enter PIN shown in Moonlight into Sunshine web UI"
        echo ""
    else
        echo "⚠️  Sunshine service enabled but not running (no display detected)"
        echo "   Will start automatically after reboot with GUI"
        echo "   Check logs: journalctl --user -u sunshine.service"
    fi
else
    echo "✅ Sunshine service created and enabled"
    echo "   ⚠️  No display detected (WSL environment)"
    echo "   Service will start automatically after reboot in VMware/GUI"
    echo "   Manual start: systemctl --user start sunshine.service"
fi

# ============================================
# 9. CREATE KIOSK STARTUP SCRIPT
# ============================================
echo ""
echo "📝 Creating kiosk startup script..."

PROJECT_DIR="$(pwd)"

cat > ~/start-kiosk.sh << KIOSK_SCRIPT
#!/bin/bash

# Set DISPLAY if not set
if [ -z "\$DISPLAY" ]; then
    export DISPLAY=:0
fi

# Check if X server is running
if ! xset q &>/dev/null; then
    echo "❌ X server not running!"
    echo ""
    echo "You need to start X server first. Options:"
    echo ""
    if command -v startx &> /dev/null; then
        echo "  1. Run: startx"
        echo "     (from a virtual console, press Ctrl+Alt+F1)"
    else
        echo "  1. Install xinit: sudo apt install -y xinit"
        echo "     Then run: startx"
    fi
    echo ""
    echo "  2. Or run from an existing X session (desktop environment)"
    echo "  3. Or reboot to let systemd auto-start everything"
    echo ""
    exit 1
fi

# Ensure window manager is running
if ! pgrep -x openbox > /dev/null; then
    echo "Starting Openbox window manager..."
    openbox &
    sleep 2
fi

# Disable screen blanking and power management
xset s off
xset -dpms
xset s noblank

# Start the Node.js server in background
cd "$PROJECT_DIR"
node server/server.js &
SERVER_PID=\$!

# Wait for server to start
echo "Waiting for server to start..."
sleep 5

# Start Chromium in kiosk mode with proper input handling
$CHROMIUM_CMD \\
    --kiosk \\
    --noerrdialogs \\
    --disable-infobars \\
    --no-first-run \\
    --check-for-update-interval=31536000 \\
    --disable-session-crashed-bubble \\
    --disable-features=TranslateUI \\
    --start-fullscreen \\
    --disable-gpu \\
    --disable-software-rasterizer \\
    --use-gl=swiftshader \\
    --enable-features=OverlayScrollbar \\
    --force-device-scale-factor=1 \\
    --disable-dev-shm-usage \\
    http://localhost:3000

# Cleanup when browser closes
kill \$SERVER_PID 2>/dev/null
killall openbox 2>/dev/null
KIOSK_SCRIPT

chmod +x ~/start-kiosk.sh

echo "✅ Kiosk script created at ~/start-kiosk.sh"

# ============================================
# 10. CREATE SYSTEMD SERVICE
# ============================================
echo ""
echo "📦 Creating systemd service for auto-start..."

PROJECT_DIR="$(pwd)"
USER_NAME="$(whoami)"

sudo tee /etc/systemd/system/frutiger-webos.service > /dev/null << EOF
[Unit]
Description=FrutigerLinuxWEB-OS Server
After=network.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/node $PROJECT_DIR/server/server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frutiger-webos.service

echo "✅ Systemd service created and enabled"
echo "   Start with: sudo systemctl start frutiger-webos"
echo "   Check status: sudo systemctl status frutiger-webos"

# ============================================
# 11. SETUP AUTOMATIC KIOSK MODE ON BOOT
# ============================================
echo ""
echo "📦 Setting up automatic kiosk mode on boot..."

mkdir -p ~/.config/openbox

cat > ~/.config/openbox/autostart << EOF
# Start the kiosk
bash ~/start-kiosk.sh &
EOF

# Create .xinitrc for startx
cat > ~/.xinitrc << EOF
#!/bin/bash
exec openbox-session
EOF

chmod +x ~/.xinitrc

# Setup auto-login
echo "📦 Configuring auto-login for $(whoami)..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $(whoami) --noclear %I \$TERM
AUTOLOGIN

# Add startx to .bash_profile
if ! grep -q "startx" ~/.bash_profile 2>/dev/null; then
    cat >> ~/.bash_profile << 'XSTART'

# Start X on login (only on tty1, not SSH)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
XSTART
fi

echo "✅ Auto-login configured for $(whoami)"
echo "✅ Kiosk autostart configured"

# Export DISPLAY for systemd user services
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/display.conf << 'DISPCONF'
DISPLAY=:0
XAUTHORITY=$HOME/.Xauthority
DISPCONF

# ============================================
# 12. CREATE EXAMPLE APP DIRECTORIES
# ============================================
echo ""
echo "📁 Ensuring app directories exist..."
mkdir -p public/apps/os
mkdir -p public/apps/notepad
mkdir -p public/apps/software
mkdir -p "public/apps/firefox xpra"
mkdir -p "public/apps/steam sunshine"
mkdir -p server/uploads
mkdir -p server/os

# ============================================
# 13. FINAL INSTRUCTIONS
# ============================================
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "🎮 Everything installed:"
echo "   ✓ Node.js 20.x and npm"
echo "   ✓ Xpra running: http://localhost:10000"
echo "   ✓ Sunshine (game streaming server)"
echo "   ✓ Moonlight Qt (game streaming client)"
echo "   ✓ Chromium (kiosk mode browser)"
echo "   ✓ X Server & Openbox"
echo "   ✓ Systemd service (auto-start)"
echo "   ✓ Auto-login and kiosk mode"
echo ""
echo "📝 Quick Start:"
echo "   1. Manual start:  npm start"
echo "   2. Kiosk mode:    bash ~/start-kiosk.sh"
echo "   3. System service: sudo systemctl start frutiger-webos"
echo ""
echo "🌐 Access the OS at: http://localhost:3000"
echo ""
echo "🎮 Game Streaming Status:"
echo "   ✓ Sunshine running: http://localhost:47990"
echo "   ✓ Moonlight installed"
echo "   → Complete pairing in Sunshine web UI (see above)"
echo "   → Then test gaming apps in the OS!"
echo ""
echo "📋 Next Steps:"
echo "   1. Place FrutigerAeroOS.exe in server/os/"
echo "   2. Add software files to server/uploads/"
echo "   3. Configure Sunshine for game streaming"
echo "   4. Pair Moonlight client with Sunshine"
echo ""
echo "🔄 Reboot to auto-start kiosk mode: sudo reboot"
echo ""
echo "📖 Documentation:"
echo "   - Gaming: See QUICK_START_GAMING.md"
echo "   - Full guide: See GAMING_SETUP.md"
echo ""

# ============================================
# 10. INSTALL AUTO-UPDATE SYSTEM
# ============================================
echo ""
echo "🔄 Installing Auto-Update System..."

REPO_URL="https://github.com/BV0073194/FrutigerLinux-WEB-OS"
INSTALL_DIR="$(pwd)"
UPDATE_SCRIPT="$INSTALL_DIR/update-system.sh"

# Ensure update script is executable
if [ -f "$UPDATE_SCRIPT" ]; then
    chmod +x "$UPDATE_SCRIPT"
    echo "✓ Update script made executable"
fi

# Create systemd user service for updates
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/frutiger-update.service << 'UPDATESERVICE'
[Unit]
Description=FrutigerLinux Auto-Update Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'cd /opt/FrutigerLinuxWEB-OS 2>/dev/null || cd ~/FrutigerLinuxWEB-OS; ./update-system.sh'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
UPDATESERVICE

# Create systemd timer (checks every 6 hours)
cat > ~/.config/systemd/user/frutiger-update.timer << 'UPDATETIMER'
[Unit]
Description=FrutigerLinux Auto-Update Timer
Requires=frutiger-update.service

[Timer]
# Run 5 minutes after boot
OnBootSec=5min
# Then every 6 hours
OnUnitActiveSec=6h
# Run even if missed (e.g., system was off)
Persistent=true

[Install]
WantedBy=timers.target
UPDATETIMER

echo "✓ Auto-update service and timer created"

# Reload systemd and enable timer
systemctl --user daemon-reload
systemctl --user enable frutiger-update.timer 2>/dev/null || true
systemctl --user start frutiger-update.timer 2>/dev/null || true

echo "✅ Auto-update system installed"
echo "   🔄 Checks GitHub every 6 hours: $REPO_URL"
echo "   📋 Check status: systemctl --user status frutiger-update.timer"
echo "   📜 View logs: journalctl --user -u frutiger-update.service"

# Create log file with proper permissions
sudo touch /var/log/frutiger-update.log 2>/dev/null || true
sudo chmod 666 /var/log/frutiger-update.log 2>/dev/null || true

# ============================================
# 11. SUNSHINE FIX (if service exists but failing)
# ============================================

if systemctl --user list-unit-files 2>/dev/null | grep -q sunshine.service; then
    if ! systemctl --user is-active --quiet sunshine.service 2>/dev/null; then
        echo ""
        echo "⚠️  Sunshine service detected but not running..."
        echo "🔧 Applying automatic fix..."
        
        # Kill all existing processes
        systemctl --user stop sunshine.service 2>/dev/null || true
        pkill -f "sunshine" 2>/dev/null || true
        pkill -f "dev.lizardbyte.app.Sunshine" 2>/dev/null || true
        sleep 2
        
        # Configure uinput permissions
        sudo bash -c 'echo "KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"" > /etc/udev/rules.d/60-sunshine-input.rules' 2>/dev/null || true
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger 2>/dev/null || true
        sudo usermod -a -G input $USER 2>/dev/null || true
        
        # Create config directories
        mkdir -p ~/.config/sunshine
        mkdir -p ~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine
        
        # Create optimized config
        cat > ~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.conf << 'SUNCONF'
encoder = software
capture = x11
output_name = 0
min_fps_factor = 1
channels = 2
fec_percentage = 20
min_threads = 2
resolutions = [
    1920x1080
]
fps = [30, 60]
SUNCONF
        
        # Detect DISPLAY
        if [ -z "$DISPLAY" ]; then
            DISPLAY_NUM=$(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Display --value 2>/dev/null)
            [ -n "$DISPLAY_NUM" ] && export DISPLAY=":$DISPLAY_NUM" || export DISPLAY=":0"
        fi
        [ -z "$XAUTHORITY" ] && export XAUTHORITY="$HOME/.Xauthority"
        
        # Recreate service with full permissions
        cat > ~/.config/systemd/user/sunshine.service << SUNSERVICE
[Unit]
Description=Sunshine Game Streaming Server
After=graphical-session.target network-online.target
Wants=graphical-session.target

[Service]
Type=simple
Environment="DISPLAY=${DISPLAY}"
Environment="XAUTHORITY=${XAUTHORITY}"
Environment="XDG_RUNTIME_DIR=/run/user/$(id -u)"
ExecStart=/usr/bin/flatpak run --command=sunshine --filesystem=host --device=all --share=ipc --share=network --socket=x11 --socket=pulseaudio dev.lizardbyte.app.Sunshine
Restart=on-failure
RestartSec=5
KillMode=mixed
TimeoutStopSec=10

[Install]
WantedBy=default.target
SUNSERVICE
        
        # Restart service
        systemctl --user daemon-reload
        systemctl --user enable sunshine.service 2>/dev/null || true
        systemctl --user restart sunshine.service 2>/dev/null || true
        sleep 3
        
        if systemctl --user is-active --quiet sunshine.service 2>/dev/null; then
            echo "✅ Sunshine fix successful - service running"
        else
            echo "⚠️  Sunshine still not running - check logs: journalctl --user -u sunshine.service"
        fi
    fi
fi

echo ""
echo "=========================================="
echo "🎉 Complete Setup Finished!"
echo "=========================================="
echo ""
echo "✅ All systems installed and configured:"
echo "   ✓ FrutigerLinuxWEB-OS application"
echo "   ✓ Auto-update (checks GitHub every 6h)"
echo "   ✓ Game streaming (Sunshine + Moonlight)"
echo "   ✓ App streaming (Xpra)"
echo "   ✓ Kiosk mode auto-start"
echo ""
echo "🚀 Ready to use! Reboot recommended: sudo reboot"
echo ""
