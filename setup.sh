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
# 4. INSTALL XPRA (for GUI app streaming)
# ============================================
echo ""
echo "📦 Installing Xpra for app streaming..."
if ! command -v xpra &> /dev/null; then
    # Save current directory
    ORIGINAL_DIR="$(pwd)"
    
    # Add official Xpra repository
    echo "📥 Adding official Xpra repository..."
    
    # Download and add Xpra GPG key
    wget -O- https://xpra.org/gpg.asc | sudo gpg --dearmor -o /usr/share/keyrings/xpra-archive-keyring.gpg
    
    # Detect Debian codename
    DEBIAN_CODENAME=$(lsb_release -cs)
    
    # Add Xpra repository with signed-by keyring
    echo "deb [signed-by=/usr/share/keyrings/xpra-archive-keyring.gpg] https://xpra.org/ $DEBIAN_CODENAME main" | sudo tee /etc/apt/sources.list.d/xpra.list > /dev/null
    
    sudo apt update
    
    # Install Xpra and xpra-html5
    if sudo apt install -y xpra xpra-html5; then
        echo "✅ Xpra and xpra-html5 installed"
        
        # Create systemd user service for Xpra
        echo "🔧 Setting up Xpra auto-start..."
        mkdir -p ~/.config/systemd/user
        
        cat > ~/.config/systemd/user/xpra.service << 'XPRA_SERVICE'
[Unit]
Description=Xpra HTML5 Server for App Streaming
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/xpra start --daemon=no --bind-tcp=0.0.0.0:10000 --html=on --start-child=xterm --exit-with-children=no
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
XPRA_SERVICE
        
        # Enable and start Xpra service
        systemctl --user daemon-reload
        systemctl --user enable xpra.service
        systemctl --user start xpra.service
        
        # Wait for Xpra to start
        sleep 3
        
        # Check if Xpra is running
        if systemctl --user is-active --quiet xpra.service; then
            echo "✅ Xpra service created and started"
            echo "   HTML5 access: http://localhost:10000"
            echo "   Apps will stream through browser automatically"
        else
            echo "⚠️  Xpra failed to start automatically"
            echo "   Start manually: systemctl --user start xpra.service"
        fi
    else
        echo "⚠️  Xpra installation failed (optional component)"
        echo "   Linux app streaming will not be available, but gaming streaming will work"
    fi
    
    # Return to original directory
    cd "$ORIGINAL_DIR"
else
    echo "✅ Xpra already installed"
fi

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

if ! flatpak list --user 2>/dev/null | grep -q sunshine; then
    set +e  # Temporarily disable exit on error for optional component
    
    # Install Sunshine via Flatpak (user install)
    echo "📥 Installing Sunshine via Flatpak (user install)..."
    flatpak install --user -y flathub dev.lizardbyte.app.Sunshine
    
    if flatpak list --user 2>/dev/null | grep -q sunshine; then
        echo "✅ Sunshine installed"
        echo "   Run with: flatpak run dev.lizardbyte.app.Sunshine"
        echo "   Web UI: http://localhost:47990"
    else
        echo "⚠️  Sunshine installation failed, but continuing setup..."
    fi
    
    set -e  # Re-enable exit on error
else
    echo "✅ Sunshine already installed"
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

# Create systemd user service for Sunshine
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/sunshine.service << 'SUNSHINE_SERVICE'
[Unit]
Description=Sunshine Game Streaming Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/flatpak run dev.lizardbyte.app.Sunshine
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SUNSHINE_SERVICE

# Enable and start Sunshine service
systemctl --user daemon-reload
systemctl --user enable sunshine.service
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
    echo "⚠️  Sunshine failed to start automatically"
    echo "   Start manually: systemctl --user start sunshine.service"
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
    cat >> ~/.bash_profile << XSTART

# Start X on login
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    startx
fi
XSTART
fi

echo "✅ Auto-login configured for $(whoami)"
echo "✅ Kiosk autostart configured"

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
