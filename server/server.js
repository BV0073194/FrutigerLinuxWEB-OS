const express = require("express");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const http = require("http");
const { Server } = require("socket.io");
const app = express();
const server = http.createServer(app);
const io = new Server(server);
const PORT = process.env.PORT || 3000;

// maps to track native app sessions and pending UAC requests
const nativeSessions = new Map(); 
// instanceId -> { appKey, pid, type, url }
const pendingUAC = new Map(); // socket.id -> { command, risks }

// ==============================
// PATHS
// ==============================
const PUBLIC_DIR = path.join(__dirname, "../public");
const APPS_DIR = path.join(PUBLIC_DIR, "apps");
const SOFTWARE_DIR = path.join(__dirname, "uploads");
const USER_CONFIG_FILE = path.join(__dirname, "userConfig.json");
const STATE_FILE = path.join(__dirname, "desktopState.json");
const OS_FILE = path.join(__dirname, "os", "FrutigerAeroOS.exe");

// ==============================
// MIDDLEWARE
// ==============================
app.use(express.json());
app.use(express.static(PUBLIC_DIR));

// ==============================
// HELPERS
// ==============================
function sha256File(filePath) {
  const buf = fs.readFileSync(filePath);
  return crypto.createHash("sha256").update(buf).digest("hex");
}

function ensureFile(file, defaultValue) {
  if (!fs.existsSync(file)) {
    fs.writeFileSync(file, JSON.stringify(defaultValue, null, 2));
  }
}

function readJSON(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

// ==============================
// BOOTSTRAP FILES
// ==============================
ensureFile(USER_CONFIG_FILE, { installedApps: {} });
ensureFile(STATE_FILE, { windows: [], zIndexCounter: 1 });

// ==============================
// API: SOFTWARE LIST
// ==============================
app.get("/api/software", (req, res) => {
  if (!fs.existsSync(SOFTWARE_DIR)) return res.json([]);

  const files = fs.readdirSync(SOFTWARE_DIR);
  res.json(
    files.map(file => {
      const fullPath = path.join(SOFTWARE_DIR, file);
      const stats = fs.statSync(fullPath);
      return {
        file,
        name: path.parse(file).name,
        version: "1.0.0",
        size: `${Math.round(stats.size / 1024 / 1024)} MB`,
        sha: sha256File(fullPath),
        icon: "⬇️"
      };
    })
  );
});

// ==============================
// API: COMMUNITY APPS
// ==============================
app.get("/api/apps", (req, res) => {
  if (!fs.existsSync(APPS_DIR)) return res.json([]);

  const DEFAULT_RULES = {
    maxInstances: 1,
    stack: false,
    resizable: true,
    minimize: true,
    maximize: true,
    startPin: false,
    addedTaskBar: false,
    sessionState: false   // ✅ enable session state restoration
  };

  const apps = fs.readdirSync(APPS_DIR)
    .filter(name => fs.statSync(path.join(APPS_DIR, name)).isDirectory())
    .map(folderName => {
      const propsPath = path.join(APPS_DIR, folderName, "app.properties.json");
      const rules = fs.existsSync(propsPath)
        ? { ...DEFAULT_RULES, ...readJSON(propsPath, {}) }
        : DEFAULT_RULES;

      return { folderName, rules };
    });

  res.json(apps);
});

// ==============================
// API: USER CONFIG
// ==============================
app.get("/api/user-config", (req, res) => {
  res.json(readJSON(USER_CONFIG_FILE, { installedApps: {} }));
});

app.post("/api/install", (req, res) => {
  const { appId, addedTo } = req.body;
  const config = readJSON(USER_CONFIG_FILE, { installedApps: {} });

  config.installedApps[appId] = {
    installed: true,
    addedTo,
    asked: true
  };

  fs.writeFileSync(USER_CONFIG_FILE, JSON.stringify(config, null, 2));
  res.json({ success: true });
});

// ==============================
// API: DESKTOP STATE
// ==============================
app.post("/api/save-state", (req, res) => {
  fs.writeFileSync(STATE_FILE, JSON.stringify(req.body, null, 2));
  res.json({ success: true });
});

app.get("/api/load-state", (req, res) => {
  res.json(readJSON(STATE_FILE, { windows: [], zIndexCounter: 1 }));
});

// ==============================
// API: APP JS FILES
// ==============================
app.get("/api/apps/:appname", (req, res) => {
  const appDir = path.join(APPS_DIR, req.params.appname);
  if (!fs.existsSync(appDir)) {
    return res.status(404).json({ error: "App not found" });
  }

  const jsFiles = fs.readdirSync(appDir).filter(f => f.endsWith(".js"));
  res.json(jsFiles);
});

// ==============================
// API: APP FILES (JS AND CSS)
// ==============================
app.get("/api/apps/:appname/files", (req, res) => {
  const appDir = path.join(APPS_DIR, req.params.appname);
  if (!fs.existsSync(appDir)) {
    return res.status(404).json({ error: "App not found" });
  }

  const jsFiles = fs.readdirSync(appDir).filter(f => f.endsWith(".js"));
  const cssFiles = fs.readdirSync(appDir).filter(f => f.endsWith(".css"));
  
  res.json({ js: jsFiles, css: cssFiles });
});

// ==============================
// DOWNLOADS
// ==============================
app.get("/apps/os", (req, res) => {
  res.download(OS_FILE);
});

app.get("/download/software/:file", (req, res) => {
  res.download(path.join(SOFTWARE_DIR, req.params.file));
});


// ==============================
// FALLBACK (SPA ROUTING)
// ==============================
app.get("*", (req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, "index.html"));
});

// ==============================
// NATIVE APP STREAM REDIRECT
// ==============================
app.get("/stream/:instanceId", (req, res) => {
  const session = nativeSessions.get(req.params.instanceId);
  if (!session || !session.url) {
    return res.status(404).send("No active stream");
  }
  res.redirect(session.url);
});


// ==============================
// START SERVER
// ==============================
server.listen(PORT, () => {
  // Initialize desktopState.json if it doesn't exist
  if (!fs.existsSync(STATE_FILE)) {
    const initialState = { windows: [], zIndexCounter: 1 };
    fs.writeFileSync(STATE_FILE, JSON.stringify(initialState, null, 2));
  }
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});

// com

const { exec } = require("child_process");

const BLACKLISTED_COMMANDS = [
  'rm -rf /',
  ':(){ :|:& };:', // fork bomb
  'mkfs',
  'dd if=',
];

const RISKY_KEYWORDS = [
  'sudo',
  'rm',
  'chmod',
  'chown',
  'apt',
  'dnf',
  'pacman',
  'systemctl',
  'service',
  'kill',
  'cat /dev',
];

app.post("/api/exec", async (req, res) => {
  const { command } = req.body;
  const socketId = req.headers["x-socket-id"];
  const socket = socketClients.get(socketId);

  if (!socket) {
    return res.status(403).json({ error: "No active session" });
  }

  // 🚫 Hard blacklist (never allowed)
  const blacklistedCommands = [
    "rm -rf /",
    ":(){ :|:& };:",
  ];

  if (blacklistedCommands.some(bad => command.includes(bad))) {
    return res.status(403).json({ error: "Command permanently blocked" });
  }

  // ⚠️ Commands requiring UAC
  const riskyPatterns = ["sudo", "rm", "dd", "mount", "chmod", "chown"];

  const risks = riskyPatterns.filter(r => command.includes(r));

  if (risks.length > 0 && !socket.uacApproved) {
    socket.emit("uac:required", {
      command,
      risks
    });

    return res.json({ pending: true });
  }

  socket.uacApproved = false; // reset after use

  exec(command, (error, stdout, stderr) => {
    console.log("🟢 EXEC CALLBACK FIRED");

    if (error) {
      console.error("🔴 EXEC ERROR:", error.message);
    }

    console.log("STDOUT:", stdout);
    console.log("STDERR:", stderr);

    socket.emit("exec:result", {
      stdout,
      stderr,
      error: error?.message || null
    });
  });
  
  res.json({ success: true });
});



// UAC socket.io
const socketClients = new Map();

io.on("connection", (socket) => {
  console.log("🔌 Client connected:", socket.id);
  socketClients.set(socket.id, socket);

  socket.on("disconnect", () => {
    socketClients.delete(socket.id);
  });

  socket.on("uac:approve", () => {
    socket.uacApproved = true;
  });

  socket.on("uac:deny", () => {
    socket.uacApproved = false;
  });

  socket.on("native:launch", ({ appKey, instanceId, command, stream }) => {
    console.log(`🎮 Launching native app: ${appKey}, stream: ${stream}, instance: ${instanceId}`);
    
    const propsPath = path.join(APPS_DIR, appKey, "app.properties.json");
    const rules = readJSON(propsPath, {});

    // trust client override only if defined in properties
    rules.command = rules.command || command;
    rules.stream = stream || rules.stream;

    if (rules.stream === "xpra") {
      launchXpra(appKey, rules, socket, instanceId);
    } else if (rules.stream === "sunshine") {
      launchSunshine(appKey, rules, socket, instanceId);
    } else {
      socket.emit("app:error", { 
        appKey,
        instanceId, 
        error: `Unknown stream type: ${rules.stream}` 
      });
    }
  });

  socket.on("native:kill", ({ instanceId }) => {
    const session = nativeSessions.get(instanceId);
    if (!session) return;

    console.log(`🛑 Killing native app instance: ${instanceId}`);
    
    if (session.type === 'xpra' && session.display) {
      // Stop xpra display properly
      exec(`xpra stop ${session.display}`, (err) => {
        if (err) console.error("Error stopping xpra:", err);
      });
    } else if (session.type === 'moonlight') {
      // Kill Moonlight client
      exec('pkill -f moonlight', (err) => {
        if (err) console.error('Error stopping Moonlight:', err);
      });
    }

    try {
      process.kill(session.pid);
    } catch (err) {
      console.error("Error killing process:", err);
    }

    nativeSessions.delete(instanceId);
  });
});
// ==============================

// App launch helper
function launchApp(appKey, rules, socket) {
  switch (rules.backend) {

    case "exec": {
      const child = exec(rules.command);
      nativeSessions.set(instanceId, {
        appKey,
        pid: child.pid,
        type: "exec"
      });

      child.stdout?.on("data", d => {
        socket.emit("app:output", { appKey, stdout: d.toString() });
      });

      child.stderr?.on("data", d => {
        socket.emit("app:output", { appKey, stderr: d.toString() });
      });
      break;
    }

    case "xpra":
      launchXpra(appKey, rules, socket);
      break;

    case "sunshine":
      launchSunshine(appKey, rules, socket);
      break;

    default:
      // web apps handled client-side
      break;
  }
}

function launchXpra(appKey, rules, socket, instanceId) {
  const display = `:${100 + Math.floor(Math.random() + 100)}`;
  const cmd = `xpra start ${display} --start-child="${rules.command}" --html=on --bind-tcp=127.0.0.1:0`;

  console.log(`🚀 Launching Xpra: ${cmd}`);

  const proc = exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("❌ Xpra launch error:", err);
      socket.emit("app:error", { appKey, instanceId, error: "Failed to launch Xpra. Is Xpra installed?" });
      return;
    }

    // Parse port from stdout
    const match = stdout.match(/port (\d+)/);
    if (!match) {
      console.error("Failed to parse Xpra port");
      socket.emit("app:error", { appKey, instanceId, error: "Failed to parse Xpra port" });
      return;
    }

    const url = `http://localhost:${match[1]}`;
    console.log(`✅ Xpra stream ready: ${url}`);

    nativeSessions.set(instanceId, {
      appKey,
      pid: proc.pid,
      type: "xpra",
      url,
      display
    });

    socket.emit("app:stream", {
      instanceId,
      appKey,
      type: "xpra",
      url
    });
  });

  proc.on('exit', (code) => {
    console.log(`Xpra process exited with code ${code}`);
    nativeSessions.delete(instanceId);
  });
}

function launchSunshine(appKey, rules, socket, instanceId) {
  // Sunshine is a game streaming SERVER - we need to launch Moonlight CLIENT
  // The command in app.properties.json should be the app to stream (e.g., "steam")
  
  // First, check if Sunshine server is running (check for flatpak process)
  exec('pgrep -f "flatpak.*sunshine"', (err, stdout) => {
    if (err || !stdout.trim()) {
      // Sunshine not running, start it via flatpak
      console.log('⚙️ Starting Sunshine server...');
      exec('flatpak run dev.lizardbyte.app.Sunshine &', (sunErr) => {
        if (sunErr) {
          console.error('❌ Failed to start Sunshine:', sunErr);
        }
      });
      
      // Wait for Sunshine to start
      setTimeout(() => launchMoonlightClient(appKey, rules, socket, instanceId), 3000);
    } else {
      // Sunshine already running
      launchMoonlightClient(appKey, rules, socket, instanceId);
    }
  });
}

function launchMoonlightClient(appKey, rules, socket, instanceId) {
  // Launch Moonlight Qt to connect to localhost Sunshine server
  // Moonlight opens in its own window (not embedded in browser)
  
  // Check if Moonlight is installed via flatpak
  exec('flatpak list 2>/dev/null | grep -i moonlight', (flatErr, flatOut) => {
    if (!flatErr && flatOut.trim()) {
      // Flatpak version found - this is the recommended method
      const appName = rules.command || 'Desktop';
      console.log(`🎮 Launching Moonlight (flatpak) for app: ${appName}`);
      
      // Launch Moonlight with DISPLAY set (important for GUI apps)
      const moonlightCmd = `DISPLAY=${process.env.DISPLAY || ':0'} flatpak run com.moonlight_stream.Moonlight stream localhost "${appName}" &`;
      executeMoonlight(moonlightCmd, appKey, socket, instanceId, rules);
      return;
    }
    
    // Try native installation
    exec('which moonlight-qt', (err, nativePath) => {
      if (!err && nativePath.trim()) {
        const appName = rules.command || 'Desktop';
        console.log(`🎮 Launching Moonlight (native) for app: ${appName}`);
        const moonlightCmd = `moonlight-qt stream localhost "${appName}" &`;
        executeMoonlight(moonlightCmd, appKey, socket, instanceId, rules);
        return;
      }
      
      // Moonlight not found
      console.error('❌ Moonlight not found');
      socket.emit("app:error", { 
        appKey, 
        instanceId, 
        error: "Moonlight Qt not installed.\n\nInstall it with:\nflatpak install flathub com.moonlight_stream.Moonlight\n\nThen pair it with Sunshine at http://localhost:47990" 
      });
    });
  });
}

function executeMoonlight(cmd, appKey, socket, instanceId, rules) {
  console.log(`🚀 Executing: ${cmd}`);
  
  const proc = exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("❌ Moonlight launch error:", err);
      console.error("stderr:", stderr);
      
      let errorMsg = "Failed to launch Moonlight.";
      
      if (stderr.includes('Failed to connect') || stderr.includes('Connection refused')) {
        errorMsg = `Cannot connect to Sunshine server.\n\n1. Make sure Sunshine is running:\n   flatpak run dev.lizardbyte.app.Sunshine\n2. Check Sunshine web UI: http://localhost:47990\n3. Make sure the app "${rules.command}" is configured in Sunshine`;
      } else if (stderr.includes('not paired') || stderr.includes('pairing')) {
        errorMsg = `Moonlight not paired with Sunshine.\n\n1. Open Moonlight manually\n2. Add PC: localhost\n3. Enter PIN from Sunshine web UI (http://localhost:47990)`;
      }
      
      socket.emit("app:error", { 
        appKey, 
        instanceId, 
        error: errorMsg
      });
      return;
    }
  });

  // Store session
  nativeSessions.set(instanceId, {
    appKey,
    pid: proc.pid,
    type: "moonlight",
    display: "external",
    command: rules.command
  });

  // Notify client that Moonlight launched
  setTimeout(() => {
    console.log(`✅ Moonlight launched externally for ${rules.command}`);
    socket.emit("app:stream", {
      instanceId,
      appKey,
      type: "moonlight",
      external: true,
      message: `Moonlight Qt launched streaming "${rules.command}". Check your desktop for the Moonlight window.`
    });
  }, 1500);

  proc.on('exit', (code) => {
    console.log(`Moonlight process exited with code ${code}`);
    nativeSessions.delete(instanceId);
  });
}
// ==============================