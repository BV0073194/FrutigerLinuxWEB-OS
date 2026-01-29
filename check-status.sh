#!/bin/bash
# Quick diagnostic script to check FrutigerLinux environment

echo "=========================================="
echo "FrutigerLinux Environment Diagnostics"
echo "=========================================="
echo ""

echo "🖥️  Display Information:"
echo "   DISPLAY: ${DISPLAY:-NOT SET}"
echo "   XAUTHORITY: ${XAUTHORITY:-NOT SET}"
echo "   Current TTY: $(tty)"
echo "   Logged in via: ${SSH_CONNECTION:+SSH}${SSH_CONNECTION:-Local Console}"
echo ""

echo "🔍 X Server Status:"
if pgrep -x Xorg > /dev/null; then
    echo "   ✅ Xorg is running"
    ps aux | grep -E "Xorg|X\s" | grep -v grep | head -1
else
    echo "   ❌ Xorg is NOT running"
    echo "   → Run 'startx' from console (not SSH)"
fi
echo ""

echo "🚀 Service Status:"
echo ""
echo "   Node.js Server (frutiger-webos):"
if systemctl --user is-active frutiger-webos.service &>/dev/null 2>&1; then
    echo "   ✅ Running"
elif sudo systemctl is-active frutiger-webos &>/dev/null 2>&1; then
    echo "   ✅ Running (system)"
else
    echo "   ❌ Not running"
    echo "   → Start: npm start (in FrutigerLinuxWEB-OS directory)"
fi

echo ""
echo "   Xpra (App Streaming):"
if systemctl --user is-active xpra.service &>/dev/null 2>&1; then
    echo "   ✅ Running on http://localhost:10000"
else
    echo "   ❌ Not running"
    echo "   → Start: systemctl --user start xpra.service"
fi

echo ""
echo "   Sunshine (Game Streaming):"
if systemctl --user is-active sunshine.service &>/dev/null 2>&1; then
    echo "   ✅ Running on http://localhost:47990"
elif pgrep -f "sunshine" > /dev/null; then
    echo "   ⚠️  Running but not as service"
else
    echo "   ❌ Not running"
    echo "   → Start: systemctl --user start sunshine.service"
fi

echo ""
echo "📦 Installed Components:"
echo ""

if command -v node &> /dev/null; then
    echo "   ✅ Node.js: $(node --version)"
else
    echo "   ❌ Node.js not found"
fi

if command -v npm &> /dev/null; then
    echo "   ✅ npm: $(npm --version)"
else
    echo "   ❌ npm not found"
fi

if command -v xpra &> /dev/null; then
    echo "   ✅ Xpra: $(xpra --version 2>&1 | head -1)"
else
    echo "   ❌ Xpra not found"
fi

if flatpak list --user 2>/dev/null | grep -q sunshine; then
    echo "   ✅ Sunshine (Flatpak)"
else
    echo "   ❌ Sunshine not found"
fi

if flatpak list --user 2>/dev/null | grep -q moonlight; then
    echo "   ✅ Moonlight (Flatpak)"
else
    echo "   ❌ Moonlight not found"
fi

if command -v chromium &> /dev/null || command -v chromium-browser &> /dev/null; then
    echo "   ✅ Chromium"
else
    echo "   ❌ Chromium not found"
fi

echo ""
echo "🌐 Network Ports:"
echo ""

if command -v ss &> /dev/null; then
    echo "   Port 3000 (Node.js): $(ss -ltn | grep :3000 | wc -l) listener(s)"
    echo "   Port 10000 (Xpra): $(ss -ltn | grep :10000 | wc -l) listener(s)"
    echo "   Port 47990 (Sunshine): $(ss -ltn | grep :47990 | wc -l) listener(s)"
else
    echo "   ⚠️  'ss' command not available"
fi

echo ""
echo "=========================================="
echo "💡 Common Issues & Solutions:"
echo "=========================================="
echo ""

if [ -n "$SSH_CONNECTION" ]; then
    echo "⚠️  You are connected via SSH!"
    echo ""
    echo "   The system is designed to run from the VMware console."
    echo "   From SSH you can:"
    echo "   • Check status: systemctl --user status xpra.service"
    echo "   • View logs: journalctl --user -u frutiger-webos"
    echo "   • Start services: systemctl --user start <service>"
    echo ""
    echo "   To use the full system:"
    echo "   1. Open VMware console directly"
    echo "   2. System should auto-login and start kiosk mode"
    echo "   3. Browser opens to http://localhost:3000 automatically"
    echo ""
fi

if [ -z "$DISPLAY" ]; then
    echo "❌ DISPLAY not set!"
    echo ""
    echo "   If you're at the console:"
    echo "   → Run: startx"
    echo ""
    echo "   If you're via SSH:"
    echo "   → SSH cannot run graphical apps"
    echo "   → Use VMware console instead"
    echo ""
fi

if ! pgrep -x Xorg > /dev/null; then
    echo "❌ X Server not running!"
    echo ""
    echo "   To start graphical session:"
    echo "   1. Make sure you're at the console (not SSH)"
    echo "   2. Run: startx"
    echo "   3. Or reboot: sudo reboot"
    echo ""
fi

if [ ! -d "/opt/FrutigerLinuxWEB-OS" ] && [ ! -d "$HOME/FrutigerLinuxWEB-OS" ]; then
    echo "❌ FrutigerLinuxWEB-OS directory not found!"
    echo ""
    echo "   Clone repository:"
    echo "   → git clone https://github.com/BV0073194/FrutigerLinux-WEB-OS"
    echo "   → cd FrutigerLinux-WEB-OS"
    echo "   → ./setup.sh"
    echo ""
fi

echo "=========================================="
echo ""
echo "📚 Quick Commands:"
echo ""
echo "   Start web server:  cd ~/FrutigerLinuxWEB-OS && npm start"
echo "   Access web UI:     http://localhost:3000"
echo "   Xpra web client:   http://localhost:10000"
echo "   Sunshine config:   http://localhost:47990"
echo ""
echo "   Check services:    systemctl --user status"
echo "   View logs:         journalctl --user -f"
echo "   Restart service:   systemctl --user restart <service>"
echo ""
