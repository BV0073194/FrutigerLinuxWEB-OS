#!/bin/bash
# Enable FrutigerLinuxWEB-OS to start on boot

echo "=========================================="
echo "Enabling Boot Services"
echo "=========================================="
echo ""

# Enable the systemd service
echo "📦 Enabling system service..."
sudo systemctl enable frutiger-webos.service
sudo systemctl daemon-reload

echo "✅ System service enabled"
echo ""

# Configure auto-login
echo "📦 Configuring auto-login..."
USER_NAME="$(whoami)"

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "✅ Auto-login configured for $USER_NAME"
echo ""

# Setup kiosk autostart
echo "📦 Setting up kiosk autostart..."

mkdir -p ~/.config/autostart

cat > ~/.config/autostart/frutiger-kiosk.desktop << EOF
[Desktop Entry]
Type=Application
Name=Frutiger WebOS Kiosk
Exec=bash ~/start-kiosk.sh
Terminal=false
EOF

# Create .xinitrc for startx
cat > ~/.xinitrc << EOF
#!/bin/bash
# Start Openbox and kiosk
exec openbox-session
EOF

chmod +x ~/.xinitrc

# Configure openbox autostart
mkdir -p ~/.config/openbox

cat > ~/.config/openbox/autostart << EOF
#!/bin/bash
# Auto-start kiosk mode
sleep 2
bash ~/start-kiosk.sh &
EOF

chmod +x ~/.config/openbox/autostart

echo "✅ Kiosk autostart configured"
echo ""

# Configure automatic X server start on login
echo "📦 Setting up X server auto-start..."

if ! grep -q "startx" ~/.bash_profile 2>/dev/null; then
    cat >> ~/.bash_profile << 'EOF'

# Auto-start X server on tty1 login
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec startx
fi
EOF
    echo "✅ X server auto-start configured"
else
    echo "✅ X server auto-start already configured"
fi

echo ""
echo "=========================================="
echo "✅ Boot Services Enabled!"
echo "=========================================="
echo ""
echo "🎯 What happens on boot:"
echo "   1. Auto-login as $USER_NAME"
echo "   2. X server starts automatically"
echo "   3. Openbox window manager launches"
echo "   4. Chromium opens in kiosk mode"
echo "   5. Web OS loads at http://localhost:3000"
echo ""
echo "🔄 To test without rebooting:"
echo "   bash ~/start-kiosk.sh"
echo ""
echo "🔄 Reboot to activate:"
echo "   sudo reboot"
echo ""
