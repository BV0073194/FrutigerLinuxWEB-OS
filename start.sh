#!/bin/bash
# Proper FrutigerLinux Startup Script
# Run this to start everything correctly

echo "=========================================="
echo "Starting FrutigerLinux System"
echo "=========================================="
echo ""

# Check if X server is running
if [ -z "$DISPLAY" ]; then
    echo "❌ No X server detected (DISPLAY not set)"
    echo ""
    echo "Are you at the graphical console or SSH?"
    echo ""
    read -p "Press Enter to check..."
    
    if [ -n "$SSH_CONNECTION" ]; then
        echo ""
        echo "⚠️  You are connected via SSH!"
        echo ""
        echo "SSH cannot run graphical applications."
        echo "You have two options:"
        echo ""
        echo "Option 1 - Start services only (recommended for SSH):"
        echo "  The services will run in background, access via browser"
        echo ""
        echo "Option 2 - Exit and use VMware console"
        echo "  Direct access to graphical environment"
        echo ""
        read -p "Continue with Option 1? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Exiting. Use VMware console instead."
            exit 0
        fi
    else
        echo "You're at the console but X isn't running."
        echo ""
        echo "The system should auto-start X on login."
        echo "Try:"
        echo "  1. Logout and login again (type: exit)"
        echo "  2. Or just reboot: sudo reboot"
        echo ""
        read -p "Reboot now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        else
            echo "Manual start not recommended. Use reboot instead."
            exit 1
        fi
    fi
fi

echo ""
echo "🔍 Checking prerequisites..."
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo "❌ Not in FrutigerLinuxWEB-OS directory!"
    echo ""
    if [ -d "/opt/FrutigerLinuxWEB-OS" ]; then
        cd /opt/FrutigerLinuxWEB-OS
        echo "✅ Changed to /opt/FrutigerLinuxWEB-OS"
    elif [ -d "$HOME/FrutigerLinuxWEB-OS" ]; then
        cd "$HOME/FrutigerLinuxWEB-OS"
        echo "✅ Changed to ~/FrutigerLinuxWEB-OS"
    else
        echo "Cannot find FrutigerLinuxWEB-OS directory!"
        exit 1
    fi
fi

# Start Xpra service
echo "🚀 Starting Xpra service..."
if systemctl --user is-active xpra.service &>/dev/null; then
    echo "   ✅ Already running"
else
    systemctl --user start xpra.service
    sleep 2
    if systemctl --user is-active xpra.service &>/dev/null; then
        echo "   ✅ Started successfully"
    else
        echo "   ⚠️  Failed to start (check: journalctl --user -u xpra.service)"
    fi
fi

# Start Sunshine service
echo "🎮 Starting Sunshine service..."
if systemctl --user is-active sunshine.service &>/dev/null; then
    echo "   ✅ Already running"
else
    systemctl --user start sunshine.service
    sleep 2
    if systemctl --user is-active sunshine.service &>/dev/null; then
        echo "   ✅ Started successfully"
    else
        echo "   ⚠️  Failed to start (check: journalctl --user -u sunshine.service)"
    fi
fi

# Start Node.js server
echo "🌐 Starting Node.js server..."
if pgrep -f "node.*server.js" > /dev/null; then
    echo "   ✅ Already running"
else
    cd server
    echo "   Starting server on port 3000..."
    node server.js &
    SERVER_PID=$!
    sleep 2
    
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "   ✅ Server started (PID: $SERVER_PID)"
    else
        echo "   ❌ Server failed to start"
        echo "   Try manually: cd ~/FrutigerLinuxWEB-OS/server && node server.js"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "✅ System Started!"
echo "=========================================="
echo ""
echo "🌐 Access the system:"
echo ""
echo "   Web Interface:  http://localhost:3000"
echo "   Xpra Client:    http://localhost:10000"
echo "   Sunshine:       http://localhost:47990"
echo ""

if [ -n "$SSH_CONNECTION" ]; then
    # User is on SSH
    MY_IP=$(hostname -I | awk '{print $1}')
    echo "   From your Windows PC: http://$MY_IP:3000"
    echo ""
fi

echo "📱 How to use:"
echo ""
echo "   1. Open browser to http://localhost:3000"
echo "   2. Click any app (Firefox, Notepad, etc.)"
echo "   3. App launches automatically"
echo ""
echo "   ⚠️  DO NOT run 'xpra', 'firefox', etc from terminal!"
echo "   ⚠️  All apps MUST be launched through the browser!"
echo ""
echo "🛑 To stop:"
echo "   Press Ctrl+C, or run: pkill -f 'node.*server.js'"
echo ""
echo "📊 Check status:"
echo "   Run: ./check-status.sh"
echo ""

# If we have DISPLAY, try to open browser
if [ -n "$DISPLAY" ] && command -v chromium &>/dev/null; then
    echo "🌐 Opening browser..."
    sleep 2
    chromium --app=http://localhost:3000 &>/dev/null &
fi

# Keep script running if server was started by us
if [ -n "$SERVER_PID" ]; then
    echo "Press Ctrl+C to stop the server..."
    wait $SERVER_PID
fi
