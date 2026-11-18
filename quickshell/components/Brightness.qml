import QtQuick
import "../services"

// Screen brightness indicator (reads from BrightnessService; supports scroll wheel)
BarPill {
    icon: BrightnessService.icon
    text: BrightnessService.ready ? (BrightnessService.percent + "%") : "--%"
    monospace: true
    onScrolled: step => BrightnessService.step(step * 5)
}
