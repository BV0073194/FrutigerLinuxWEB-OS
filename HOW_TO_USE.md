# 🚨 IMPORTANT: How to Use FrutigerLinux Correctly

## The Problem You're Having

If you're having to run `sudo startx app-name` for every app, you're using the system incorrectly!

## How It SHOULD Work

### 1. **Boot into VMware Console (NOT SSH)**

The system is designed to work from the **graphical console** in VMware:

```
VMware → Power On → Auto-login → Chromium opens automatically
```

**NOT** via SSH: `ssh user@192.168.x.x` ❌

### 2. **System Auto-Starts Everything**

When you boot from the console:
- ✅ X Server starts automatically
- ✅ Browser opens in kiosk mode
- ✅ Node.js server starts
- ✅ Xpra service runs in background
- ✅ Sunshine service runs in background

### 3. **Use the Web Interface**

All apps launch **through the web browser** at `http://localhost:3000`:

```
Browser → Click "Firefox" app → Opens in iframe (Xpra)
Browser → Click "Steam" app → Moonlight launches
```

**NOT** from command line! ❌

## Correct Usage Flow

```
┌─────────────────────────────────────────┐
│  Step 1: Open VMware Console            │
│  (Not SSH!)                              │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│  Step 2: System Auto-Boots              │
│  • Auto-login                            │
│  • X Server starts                       │
│  • Services start (Xpra, Sunshine)       │
│  • Chromium opens to localhost:3000      │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│  Step 3: Use Apps in Browser            │
│  • Click Firefox → Xpra streams it       │
│  • Click Steam → Moonlight opens         │
│  • Click Notepad → Opens in browser      │
└─────────────────────────────────────────┘
```

## If You're Using SSH...

### SSH is for **management only**, not regular use!

From SSH you can:
- ✅ Check status: `./check-status.sh`
- ✅ View logs: `journalctl --user -u xpra.service`
- ✅ Update code: `git pull`
- ✅ Restart services: `systemctl --user restart sunshine.service`

But you **CANNOT**:
- ❌ Run graphical apps directly
- ❌ Open Firefox, Steam, etc from command line
- ❌ Use the web interface properly (DISPLAY not set)

### To Actually Use the System:

1. Close your SSH session
2. Open VMware console
3. Let auto-login happen
4. Browser opens automatically
5. Click apps in the browser

## Troubleshooting

### "I'm at the console but nothing happens"

```bash
# Check if you're actually logged in graphically
echo $DISPLAY
# Should show: :0

# Check if services are running
./check-status.sh

# Manually start X if needed (shouldn't be necessary)
startx
```

### "Apps don't launch from the browser"

```bash
# Check Node.js server is running
cd ~/FrutigerLinuxWEB-OS
npm start

# Open browser to:
http://localhost:3000
```

### "I want to test from my Windows machine"

From Windows, access the VM's web interface:
```
http://192.168.x.x:3000
```
(Replace with your VM's IP)

This works for:
- ✅ Browser-based apps (Notepad, Software)
- ✅ Xpra apps (Firefox) - streams to browser
- ❌ Sunshine/Moonlight - needs to be on the VM

## Quick Diagnostic

Run this from SSH or console:

```bash
cd ~/FrutigerLinuxWEB-OS
chmod +x check-status.sh
./check-status.sh
```

This will tell you:
- ✅ What's working
- ❌ What's not working
- 💡 How to fix it

## Architecture Reminder

```
┌──────────────────────────────────────────────┐
│  VMware Console (Graphical)                  │
│  ┌────────────────────────────────────────┐  │
│  │  Chromium Browser (Kiosk Mode)         │  │
│  │  http://localhost:3000                 │  │
│  │                                         │  │
│  │  [Firefox] [Steam] [Notepad] [Desktop] │  │
│  │     ↓         ↓        ↓         ↓     │  │
│  │   Xpra    Moonlight  Browser  Moonlight│  │
│  └────────────────────────────────────────┘  │
│                                               │
│  Background Services (systemd):               │
│  • Node.js server (port 3000)                │
│  • Xpra server (port 10000)                  │
│  • Sunshine server (port 47990)              │
└──────────────────────────────────────────────┘
```

## The Right Way vs Wrong Way

### ❌ WRONG (What you were doing):

```bash
ssh user@vm
sudo startx firefox  # This doesn't make sense!
```

### ✅ RIGHT:

**Option 1: VMware Console**
```
1. Open VMware console
2. System auto-boots to browser
3. Click "Firefox" app
4. Firefox streams via Xpra
```

**Option 2: Remote Browser**
```
1. VM is running with auto-login
2. From Windows: http://192.168.x.x:3000
3. Click apps
4. They run on VM, display in browser
```

## Summary

- 🖥️ Use **VMware console** for full experience
- 🌐 Use **web browser** to launch apps
- 🔧 Use **SSH** only for management
- 🚫 **Never** run `startx app-name` manually
- 📱 Apps are **not** command-line programs in this system

## Still Confused?

Run the diagnostic:
```bash
./check-status.sh
```

It will tell you exactly what's wrong and how to fix it!
