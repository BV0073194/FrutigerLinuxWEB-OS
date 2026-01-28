async function downloadOS(caller) {
    const res = await fetch("/download/os");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = "FrutigerAeroOS.exe";
    a.click();

    URL.revokeObjectURL(url);
    caller.getRootNode().getElementById("osStatus").textContent = "Downloaded!";
    setTimeout(() => {
        caller.getRootNode().getElementById("osStatus").textContent = "Ready";
    }, 3000);
}