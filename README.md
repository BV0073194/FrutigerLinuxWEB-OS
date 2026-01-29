"# FrutigerLinuxWEB-OS

A web-based operating system interface with integrated app streaming, game streaming, and auto-update capabilities.

## 🚨 IMPORTANT: Read This First!

**[📖 HOW_TO_USE.md](HOW_TO_USE.md) - READ THIS IF YOU'RE HAVING ISSUES!**

Common mistake: Running `sudo startx app-name` ❌  
Correct way: Use the VMware console → browser opens automatically → click apps ✅

## Quick Start

### Installation

```bash
git clone https://github.com/BV0073194/FrutigerLinux-WEB-OS
cd FrutigerLinuxWEB-OS
./setup.sh
```

### First Run

**From VMware Console (NOT SSH!):**
1. Boot VM → Auto-login happens
2. Browser opens automatically to http://localhost:3000
3. Click apps to use them

**For Diagnostics:**
```bash
./check-status.sh
```

## Features

- 🖥️ **Web-based OS Interface** - Full desktop environment in browser
- 🎮 **Game Streaming** - Sunshine/Moonlight integration
- 📱 **App Streaming** - Xpra for Linux applications
- 🔄 **Auto-Update** - Pulls from GitHub every 6 hours
- 🚀 **Kiosk Mode** - Auto-starts on boot

## Documentation

- **[HOW_TO_USE.md](HOW_TO_USE.md)** - Important usage guide (READ THIS!)
- **[QUICK_START_GAMING.md](QUICK_START_GAMING.md)** - Gaming setup
- **[GAMING_SETUP.md](GAMING_SETUP.md)** - Detailed gaming guide
- **[ISO_BUILD_GUIDE.md](ISO_BUILD_GUIDE.md)** - Create custom ISO

## Architecture

- **Frontend**: Vanilla JS, HTML, CSS
- **Backend**: Node.js + Express + Socket.io
- **Streaming**: Xpra (apps), Sunshine/Moonlight (games)
- **Platform**: Debian 13+ (Trixie/Forky)

## Services

All services run automatically via systemd:
- **Node.js Server** (port 3000) - Main web interface
- **Xpra** (port 10000) - App streaming
- **Sunshine** (port 47990) - Game streaming

Check status: `systemctl --user status`

## Support

Having issues? Run diagnostics:
```bash
cd ~/FrutigerLinuxWEB-OS
./check-status.sh
```

## License

MIT
" 
