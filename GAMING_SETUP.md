# Game Streaming Setup (Sunshine + Moonlight)

## How It Works

This system uses **two separate components** for game streaming:

1. **Sunshine** = Server (runs on this machine, streams games OUT)
2. **Moonlight Qt** = Client (receives stream, displays games)

**Important:** Moonlight opens in its own window, NOT in the browser!

## Installation

### Automatic (via setup.sh)
```bash
./setup.sh --with-sunshine
```
This will:
- Install Sunshine server
- Ask if you want to install Moonlight client
- Configure both automatically

### Manual Installation

#### Sunshine Server
```bash
# Via Flatpak (recommended)
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub dev.lizardbyte.app.Sunshine

# Run Sunshine
flatpak run dev.lizardbyte.app.Sunshine
```

#### Moonlight Client
```bash
# Via Flatpak (recommended)
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.moonlight_stream.Moonlight

# Run Moonlight
flatpak run com.moonlight_stream.Moonlight
```

## First-Time Setup

### 1. Configure Sunshine
```bash
# Start Sunshine
flatpak run dev.lizardbyte.app.Sunshine
```
- Open browser to http://localhost:47990
- Create username/password
- Go to "Configuration" → "Applications"
- Add apps to stream (Steam, Desktop, etc.)

### 2. Pair Moonlight with Sunshine
```bash
# Launch Moonlight
flatpak run com.moonlight_stream.Moonlight
```
- Click "Add PC"
- Enter "localhost" or your PC's IP
- Enter PIN shown in Sunshine web UI

## Usage

### From FrutigerLinuxWEB-OS

1. Click "Steam (Game Streaming)" app in the OS
2. Moonlight Qt will launch in a **separate window**
3. The browser window shows: "Moonlight Qt Launched"
4. Look for Moonlight on your desktop (outside the browser)
5. Close the browser window when done to stop streaming

### Direct Launch (for testing)
```bash
# Launch Sunshine server
flatpak run dev.lizardbyte.app.Sunshine &

# Launch Moonlight and stream Desktop
flatpak run com.moonlight_stream.Moonlight stream localhost "Desktop"

# Or stream specific app
flatpak run com.moonlight_stream.Moonlight stream localhost "Steam"
```

## Architecture

```
┌─────────────────────────────────────────────┐
│  FrutigerLinuxWEB-OS (Browser)              │
│  ┌────────────────────────────────────────┐ │
│  │ User clicks "Steam" app                │ │
│  │ → Sends command to Node.js server      │ │
│  └────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────┐
│  Node.js Server                              │
│  1. Checks if Sunshine is running           │
│  2. Starts Sunshine if needed               │
│  3. Launches Moonlight Qt client            │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴──────────┐
        ↓                    ↓
┌──────────────┐    ┌────────────────┐
│   Sunshine   │    │  Moonlight Qt  │
│   (Server)   │───→│    (Client)    │
│ Port 47989   │    │  Separate Win  │
└──────────────┘    └────────────────┘
                             │
                             ↓
                    ┌────────────────┐
                    │  Game/Desktop  │
                    │   Displayed    │
                    └────────────────┘
```

## Comparison: Xpra vs Moonlight

| Feature | Xpra | Moonlight/Sunshine |
|---------|------|-------------------|
| **Display** | In browser iframe | Separate window |
| **Use Case** | Regular Linux apps (Firefox, terminals) | Games & Desktop streaming |
| **Performance** | Good for apps | Optimized for gaming |
| **Setup** | Simple | Requires pairing |
| **Network** | Works locally | LAN or Internet |

## Troubleshooting

### "Moonlight Qt not installed"
```bash
flatpak install flathub com.moonlight_stream.Moonlight
```

### "Failed to launch Moonlight"
1. Make sure Sunshine is configured: http://localhost:47990
2. Pair Moonlight manually first
3. Test outside the OS: `flatpak run com.moonlight_stream.Moonlight`

### Sunshine not starting
```bash
# Check if running
pgrep sunshine

# Start manually
sunshine &

# Check logs
journalctl -u sunshine --follow
```

### Moonlight can't find host
1. Make sure Sunshine is running: `pgrep sunshine`
2. Check Sunshine web UI: http://localhost:47990
3. Try pairing again in Moonlight

## Creating Custom Game Streaming Apps

Create a folder in `public/apps/` with this structure:

```json
{
  "appname": "mygame",
  "appTitle": "My Game (Streaming)",
  "backend": "native",
  "stream": "sunshine",
  "command": "MyGame",
  "maxInstances": 1
}
```

The `command` should match an app configured in Sunshine's web UI.

## Resources

- Sunshine Documentation: https://docs.lizardbyte.dev/projects/sunshine/
- Moonlight Project: https://moonlight-stream.org/
- GitHub Sunshine: https://github.com/LizardByte/Sunshine
- GitHub Moonlight: https://github.com/moonlight-stream/moonlight-qt
