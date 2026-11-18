import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Idle & auto-lock daemon (dim screen -> lock session -> turn off display)
Scope {
    id: root

    signal lockRequested()

    property int savedBrightness: -1

    // 5 minutes: dim screen brightness (only if backlight exists and is above 15%)
    IdleMonitor {
        timeout: 300
        onIsIdleChanged: {
            if (isIdle) {
                if (BrightnessService.available && BrightnessService.percent > 15) {
                    root.savedBrightness = BrightnessService.percent;
                    BrightnessService.set(15);
                }
            } else if (root.savedBrightness > 0) {
                BrightnessService.set(root.savedBrightness);
                root.savedBrightness = -1;
            }
        }
    }

    // 10 minutes: lock screen
    IdleMonitor {
        timeout: 600
        onIsIdleChanged: {
            if (isIdle) {
                root.lockRequested();
            }
        }
    }

    // 15 minutes: turn off monitors via DPMS
    IdleMonitor {
        timeout: 900
        onIsIdleChanged: {
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", isIdle ? "off" : "on"]);
        }
    }
}
