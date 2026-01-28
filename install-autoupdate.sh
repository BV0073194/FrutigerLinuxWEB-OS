#!/bin/bash
# Install Auto-Update System for FrutigerLinux
# This script sets up systemd timer for automatic updates

set -e

echo "Installing FrutigerLinux Auto-Update System..."

INSTALL_DIR="/opt/FrutigerLinuxWEB-OS"
UPDATE_SCRIPT="$INSTALL_DIR/update-system.sh"

# Ensure update script is executable
if [ -f "$UPDATE_SCRIPT" ]; then
    chmod +x "$UPDATE_SCRIPT"
    echo "✓ Update script made executable"
else
    echo "✗ ERROR: Update script not found at $UPDATE_SCRIPT"
    exit 1
fi

# Create systemd user service for updates
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/frutiger-update.service << 'EOF'
[Unit]
Description=FrutigerLinux Auto-Update Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/FrutigerLinuxWEB-OS/update-system.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# Create systemd timer (checks every 6 hours)
cat > ~/.config/systemd/user/frutiger-update.timer << 'EOF'
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
EOF

echo "✓ Systemd service and timer created"

# Reload systemd and enable timer
systemctl --user daemon-reload
systemctl --user enable frutiger-update.timer
systemctl --user start frutiger-update.timer

echo "✓ Auto-update timer enabled and started"

# Show timer status
echo ""
echo "Auto-update system installed successfully!"
echo "Timer will check for updates:"
echo "  - 5 minutes after boot"
echo "  - Every 6 hours after that"
echo ""
echo "Check status: systemctl --user status frutiger-update.timer"
echo "View logs: journalctl --user -u frutiger-update.service"
echo "Manual update: $UPDATE_SCRIPT"
echo ""

# Create log file with proper permissions
sudo touch /var/log/frutiger-update.log
sudo chmod 666 /var/log/frutiger-update.log
echo "✓ Log file created at /var/log/frutiger-update.log"

# Run first update check
echo "Running initial update check..."
"$UPDATE_SCRIPT"
echo "✓ Initial update check completed"
