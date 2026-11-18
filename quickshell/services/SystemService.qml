pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Global system service: user profile info, CPU/RAM/Temp stats, power actions, and screenshot/wallpaper helpers
Singleton {
    id: root

    // User profile & preferences
    property string username: ""
    property string fullName: ""
    property string hostname: ""
    property string email: ""
    property string avatarPath: ""
    property string defaultAssistant: "agy"

    // Wallpapers
    property var wallpapers: []
    property string currentWallpaper: ""

    // System monitor
    property int cpuPercent: 0
    property int ramPercent: 0
    property int tempCelsius: 0
    property bool fastPolling: false

    // Internal CPU delta tracking
    property real prevTotal: 0
    property real prevIdle: 0

    readonly property string userFilePath: Qt.resolvedUrl("../config/user.json").toString().replace(/^file:\/\//, "")

    readonly property var powerOptions: [
        { id: "lock",     icon: "󰌾", title: "Lock" },
        { id: "suspend",  icon: "󰤄", title: "Suspend" },
        { id: "reboot",   icon: "󰜉", title: "Reboot" },
        { id: "shutdown", icon: "⏻", title: "Shutdown" },
        { id: "logout",   icon: "󰍃", title: "Log Out" }
    ]

    function executePowerAction(actionId) {
        if (actionId === "lock") {
            Quickshell.execDetached(["qs", "ipc", "call", "lock", "lock"]);
        } else if (actionId === "suspend") {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (actionId === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (actionId === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        } else if (actionId === "logout") {
            Quickshell.execDetached([
                "sh", "-c",
                "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit"
            ]);
        }
    }

    function takeScreenshot() {
        Quickshell.execDetached([
            "sh", "-c",
            "dir=\"$HOME/Pictures/Screenshots\" && mkdir -p \"$dir\" && " +
            "sleep 0.2 && region=$(slurp) && [ -n \"$region\" ] && " +
            "file=\"$dir/$(date +%Y-%m-%d_%H-%M-%S).png\" && " +
            "grim -g \"$region\" \"$file\" && " +
            "(command -v wl-copy >/dev/null 2>&1 && wl-copy < \"$file\" || true) && " +
            "(command -v notify-send >/dev/null 2>&1 && notify-send -i \"$file\" 'Screenshot Captured' \"Saved to ~/Pictures/Screenshots\" || true)"
        ]);
    }

    function saveUserConfig() {
        userFile.setText(JSON.stringify({
            fullName: fullName,
            email: email,
            defaultAssistant: defaultAssistant
        }, null, 4) + "\n");
    }

    function saveUserProfile(newFullName, newEmail) {
        fullName = newFullName.trim() !== "" ? newFullName.trim() : username;
        email = newEmail.trim();
        saveUserConfig();
    }

    function setAssistant(cmd) {
        if (cmd.trim() === "") return;
        defaultAssistant = cmd.trim();
        saveUserConfig();
    }

    function launchAssistant() {
        const escaped = defaultAssistant.replace(/'/g, "'\\''");
        Quickshell.execDetached([
            "sh", "-c",
            "for term in \"$TERMINAL\" kitty ghostty alacritty foot wezterm; do " +
            "  if [ -n \"$term\" ] && command -v \"$term\" >/dev/null 2>&1; then " +
            "    exec \"$term\" -e sh -lc '" + escaped + "'; " +
            "  fi; " +
            "done"
        ]);
    }

    function pickAvatar() {
        avatarPickerProc.running = true;
    }

    function refreshWallpapers() {
        wallpaperListProc.running = true;
    }

    function setWallpaper(imagePath) {
        if (!imagePath) return;
        currentWallpaper = imagePath;
        const escaped = imagePath.replace(/'/g, "'\\''");
        Quickshell.execDetached([
            "sh", "-c",
            "printf 'wallpaper {\\n    monitor =\\n    path = %s\\n    fit_mode = cover\\n}\\n' '" + escaped + "' > \"$HOME/.config/hypr/hyprpaper.conf\" && " +
            "(hyprctl hyprpaper reload \"," + escaped + "\" >/dev/null 2>&1 || (pkill -x hyprpaper; hyprpaper >/dev/null 2>&1 &))"
        ]);
    }

    function pickWallpaper() {
        wallpaperPickerProc.running = true;
    }

    Process {
        id: wallpaperListProc
        command: [
            "sh", "-c",
            "awk -F'=' '/^\\s*path\\s*=/{gsub(/^[ \\t]+|[ \\t]+$/, \"\", $2); print $2; exit}' \"$HOME/.config/hypr/hyprpaper.conf\" 2>/dev/null; " +
            "echo '---'; " +
            "find \"$HOME/Pictures/Wallpapers\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---\n");
                if (parts.length >= 1) {
                    root.currentWallpaper = parts[0].trim();
                }
                if (parts.length >= 2) {
                    root.wallpapers = parts[1].trim().split("\n").filter(p => p !== "");
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: wallpaperPickerProc
        command: [
            "sh", "-c",
            "mkdir -p \"$HOME/Pictures/Wallpapers\"; " +
            "if command -v zenity >/dev/null 2>&1; then " +
            "  zenity --file-selection --filename=\"$HOME/Pictures/Wallpapers/\" --title='Select Wallpaper' --file-filter='Images | *.png *.jpg *.jpeg *.webp'; " +
            "elif command -v kdialog >/dev/null 2>&1; then " +
            "  kdialog --getopenfilename \"$HOME/Pictures/Wallpapers\" '*.png *.jpg *.jpeg *.webp'; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const chosen = this.text.trim();
                if (chosen !== "") {
                    root.setWallpaper(chosen);
                    root.refreshWallpapers();
                }
            }
        }
    }

    function loadUserOverrides(raw) {
        try {
            const data = JSON.parse(raw);
            if (data.fullName && data.fullName.trim() !== "") root.fullName = data.fullName.trim();
            if (data.email !== undefined && data.email.trim() !== "") root.email = data.email.trim();
            if (data.defaultAssistant && data.defaultAssistant.trim() !== "") root.defaultAssistant = data.defaultAssistant.trim();
        } catch (e) {
            // Ignore if user.json doesn't exist or is empty
        }
    }

    FileView {
        id: userFile
        path: root.userFilePath
        preload: true
        onLoaded: root.loadUserOverrides(userFile.text())
    }

    Process {
        id: avatarPickerProc
        command: [
            "sh", "-c",
            "if command -v zenity >/dev/null 2>&1; then " +
            "  file=$(zenity --file-selection --title='Select Profile Picture' --file-filter='Images | *.png *.jpg *.jpeg *.webp'); " +
            "elif command -v kdialog >/dev/null 2>&1; then " +
            "  file=$(kdialog --getopenfilename \"$HOME\" '*.png *.jpg *.jpeg *.webp'); " +
            "fi; " +
            "if [ -n \"$file\" ] && [ -f \"$file\" ]; then " +
            "  cp \"$file\" \"$HOME/.face\" && echo \"$HOME/.face\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    root.avatarPath = "";
                    root.avatarPath = path;
                }
            }
        }
    }

    // Load system user info once at startup
    Process {
        id: userProc
        command: [
            "sh", "-c",
            "u=$(whoami); " +
            "fn=$(getent passwd \"$u\" | cut -d: -f5 | cut -d, -f1); " +
            "hn=$(cat /etc/hostname 2>/dev/null || hostname); " +
            "em=$(git config --global user.email 2>/dev/null || true); " +
            "av=''; " +
            "for p in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$u\"; do " +
            "  if [ -f \"$p\" ]; then av=\"$p\"; break; fi; " +
            "done; " +
            "printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$u\" \"$fn\" \"$hn\" \"$em\" \"$av\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.username = lines[0] ?? "";
                if (root.fullName === "") {
                    root.fullName = (lines[1] && lines[1] !== "") ? lines[1] : root.username;
                }
                root.hostname = lines[2] ?? "";
                if (root.email === "") {
                    root.email = lines[3] ?? "";
                }
                root.avatarPath = lines[4] ?? "";
                root.loadUserOverrides(userFile.text());
            }
        }
        Component.onCompleted: running = true
    }

    // Poll CPU, RAM, and CPU thermal sensor
    Process {
        id: statsProc
        command: [
            "sh", "-c",
            "head -n1 /proc/stat; " +
            "awk '/MemTotal|MemAvailable/ {print $1, $2}' /proc/meminfo; " +
            "t=''; " +
            "for h in /sys/class/hwmon/hwmon*; do " +
            "  name=$(cat \"$h/name\" 2>/dev/null); " +
            "  case \"$name\" in k10temp|coretemp|cpu_thermal|x86_pkg_temp|zenpower) " +
            "    if [ -r \"$h/temp1_input\" ]; then t=$(cat \"$h/temp1_input\" 2>/dev/null); break; fi ;; " +
            "  esac; " +
            "done; " +
            "[ -z \"$t\" ] && t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); " +
            "echo \"$t\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                if (lines.length < 4) return;

                const cpuParts = lines[0].trim().split(/\s+/).slice(1).map(Number);
                if (cpuParts.length >= 4) {
                    const idle = cpuParts[3] + (cpuParts[4] || 0);
                    const total = cpuParts.reduce((a, b) => a + b, 0);
                    if (root.prevTotal > 0 && total > root.prevTotal) {
                        const dTotal = total - root.prevTotal;
                        const dIdle = idle - root.prevIdle;
                        root.cpuPercent = Math.round(((dTotal - dIdle) / dTotal) * 100);
                    }
                    root.prevTotal = total;
                    root.prevIdle = idle;
                }

                let totalMem = 0;
                let availMem = 0;
                for (let i = 1; i < lines.length - 1; i++) {
                    if (lines[i].startsWith("MemTotal:")) totalMem = parseInt(lines[i].split(/\s+/)[1]);
                    if (lines[i].startsWith("MemAvailable:")) availMem = parseInt(lines[i].split(/\s+/)[1]);
                }
                if (totalMem > 0) {
                    root.ramPercent = Math.round(((totalMem - availMem) / totalMem) * 100);
                }

                const rawTemp = parseInt(lines[lines.length - 1]);
                if (!isNaN(rawTemp) && rawTemp > 0) {
                    root.tempCelsius = Math.round(rawTemp > 1000 ? rawTemp / 1000 : rawTemp);
                }
            }
        }
    }

    onFastPollingChanged: {
        if (fastPolling) {
            statsProc.running = true;
        }
    }

    // Adaptive polling: 2s when Sidebar is visible, 15s in background for thermal alerts
    Timer {
        interval: root.fastPolling ? 2000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }
}
