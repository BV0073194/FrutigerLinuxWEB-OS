export function init() {
  document.getElementById("downloadOsBtn").addEventListener("click", async () => {
    const res = await fetch("/download/os");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = "FrutigerAeroOS.exe";
    a.click();

    URL.revokeObjectURL(url);
    document.getElementById("osStatus").textContent = "Downloaded!";
  });
}