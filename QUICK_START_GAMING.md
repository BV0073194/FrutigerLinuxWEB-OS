# Quick Start: Game Streaming

## 🚀 First Time Setup (5 minutes)

### Step 1: Install Everything
```bash
cd /path/to/FrutigerLinuxWEB-OS
./setup.sh --with-sunshine
# Answer 'y' when asked about Moonlight
```

### Step 2: Configure Sunshine
```bash
# Start Sunshine (in background)
flatpak run dev.lizardbyte.app.Sunshine &

# Open web browser
xdg-open http://localhost:47990
```

1. Create username and password
2. Go to "Configuration" → "Applications"
3. Click "Add New"
4. Add these apps:
   - Name: `Desktop`, Command: `Desktop`
   - Name: `Steam`, Command: `steam`
   - Name: `Firefox`, Command: `firefox`

### Step 3: Pair Moonlight
```bash
# Launch Moonlight
flatpak run com.moonlight_stream.Moonlight
```

1. Click "+" or "Add PC"
2. Type: `localhost`
3. Go back to Sunshine web UI (http://localhost:47990)
4. Look for "PIN Request" notification
5. Enter PIN in Moonlight
6. Click "Pair"

### Step 4: Test It
```bash
# Start the Node.js server
npm start

# Open browser to http://localhost:3000
# Click "Steam (Game Streaming)" or "Desktop Streaming"
```

## 📱 Usage

### From Your Web OS
1. Open FrutigerLinuxWEB-OS in browser (http://localhost:3000)
2. Click any game streaming app:
   - **Desktop Streaming** - Stream your entire desktop
   - **Steam (Game Streaming)** - Stream Steam games
3. Moonlight window opens on your desktop
4. Play!
5. Close the browser window when done

### Available Streaming Apps
- `Desktop Streaming` - Full desktop access
- `Steam (Game Streaming)` - Steam Big Picture / Games
- Create your own by copying the app folder structure

## 🐛 Common Issues

### "Moonlight Qt not installed"
```bash
flatpak install flathub com.moonlight_stream.Moonlight
```

### "Failed to launch Moonlight"
Check if Sunshine is running:
```bash
# Check process
pgrep -f sunshine

# If not running, start it
flatpak run dev.lizardbyte.app.Sunshine &
```

### "Connection refused"
1. Make sure Sunshine is running: `http://localhost:47990`
2. Check Sunshine has the app configured
3. Re-pair Moonlight if needed

### "App not found"
The app must be configured in Sunshine's web UI:
1. Go to http://localhost:47990
2. Configuration → Applications
3. Make sure app name matches exactly (case-sensitive!)

### Moonlight window doesn't appear
```bash
# Set DISPLAY if needed
export DISPLAY=:0

# Try launching manually
flatpak run com.moonlight_stream.Moonlight stream localhost "Desktop"
```

## ⚙️ Advanced

### Run Sunshine on Startup
```bash
# Create systemd user service
mkdir -p ~/.config/systemd/user/
cat > ~/.config/systemd/user/sunshine.service <<EOF
[Unit]
Description=Sunshine Game Streaming Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/flatpak run dev.lizardbyte.app.Sunshine
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Enable and start
systemctl --user enable sunshine.service
systemctl --user start sunshine.service
```

### Create Custom Game App
1. Copy `public/apps/steam sunshine/` folder
2. Rename to your game name
3. Edit `app.properties.json`:
```json
{
  "appname": "mygame",
  "appTitle": "My Game",
  "backend": "native",
  "stream": "sunshine",
  "command": "mygame"
}
```
4. Make sure the command matches Sunshine configuration
5. Restart Node.js server

### Check Logs
```bash
# Node.js server logs
npm start

# Sunshine logs
journalctl --user -u sunshine -f

# Moonlight logs
flatpak run --command=sh com.moonlight_stream.Moonlight
# Inside container: check ~/.config/Moonlight Game Streaming Project/
```

## 🎮 Recommended Settings

### Sunshine (for gaming)
- Resolution: Match your display
- FPS: 60 (or 120 for competitive)
- Bitrate: 20 Mbps (LAN), 10 Mbps (WiFi)
- Encoder: NVENC (NVIDIA), AMF (AMD), or Software

### Moonlight (performance)
- Video codec: H.265 (HEVC) for better quality
- Hardware decoding: Enabled
- V-Sync: Off (lower latency)
- Frame pacing: Enabled

### For Desktop Streaming
- Lower bitrate (5-10 Mbps) for less bandwidth
- 30 FPS is usually fine for desktop work
- Enable mouse acceleration

## 📚 Learn More
- Full guide: [GAMING_SETUP.md](GAMING_SETUP.md)
- Sunshine docs: https://docs.lizardbyte.dev/projects/sunshine/
- Moonlight docs: https://github.com/moonlight-stream/moonlight-docs/wiki
