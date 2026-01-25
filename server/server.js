const express = require("express");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, "../public")));

const SOFTWARE_DIR = path.join(__dirname, "uploads");
const OS_FILE = path.join(__dirname, "os", "FrutigerAeroOS.exe");

// Generate SHA256 for file
function sha256File(filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  const hashSum = crypto.createHash("sha256");
  hashSum.update(fileBuffer);
  return hashSum.digest("hex");
}

// API - list software
app.get("/api/software", (req, res) => {
  const files = fs.readdirSync(SOFTWARE_DIR);
  const software = files.map((file) => {
    const fullPath = path.join(SOFTWARE_DIR, file);
    const stats = fs.statSync(fullPath);
    const sha = sha256File(fullPath);

    return {
      file,
      name: path.parse(file).name,
      version: "1.0.0",
      size: `${Math.round(stats.size / 1024 / 1024)} MB`,
      sha,
      icon: "⬇️",
    };
  });

  res.json(software);
});

// Download OS
app.get("/download/os", (req, res) => {
  res.download(OS_FILE);
});

// Download software
app.get("/download/software/:file", (req, res) => {
  const file = req.params.file;
  const fullPath = path.join(SOFTWARE_DIR, file);
  res.download(fullPath);
});

// Serve the software page
app.get("/software", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/software.html"));
});

// fallback
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});


app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
