pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Global screen brightness service (uses brightnessctl -m)
Singleton {
    id: root

    property int percent: 0
    property bool ready: false
    property bool available: false

    signal updated(int newPercent)

    function refresh() {
        if (brightnessProc.running) {
            brightnessProc.running = false;
        }
        brightnessProc.running = true;
    }

    function set(targetPercent) {
        const clamped = Math.max(1, Math.min(100, Math.round(targetPercent)));
        percent = clamped;
        ready = true;
        available = true;
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
    }

    function step(delta) {
        set(percent + delta);
    }

    // Nerd Font icon based on brightness level
    readonly property string icon: {
        if (percent <= 30) return "󰃞";
        if (percent <= 70) return "󰃟";
        return "󰃠";
    }

    // Output format: device,class,current,percent%,max
    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",");
                if (parts.length >= 4) {
                    const parsed = parseInt(parts[3]);
                    if (!isNaN(parsed)) {
                        root.percent = parsed;
                        root.ready = true;
                        root.available = true;
                        root.updated(parsed);
                    }
                }
            }
        }
    }

    // Poll every 10s as fallback for external changes; instant updates happen via set() and refresh()
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
