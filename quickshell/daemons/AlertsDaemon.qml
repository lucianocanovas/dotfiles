import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../services"

// Background system alerts daemon (low battery & high CPU temperature)
Scope {
    id: root

    property bool warnedLowBattery: false
    property bool warnedCriticalBattery: false
    property bool warnedHighTemp: false

    readonly property var bat: UPower.displayDevice
    readonly property int batPercent: Math.round((bat?.percentage ?? 1) * 100)
    readonly property bool isDischarging: bat?.state === UPowerDeviceState.Discharging

    onBatPercentChanged: checkBattery()
    onIsDischargingChanged: checkBattery()

    function checkBattery() {
        if (!isDischarging) {
            warnedLowBattery = false;
            warnedCriticalBattery = false;
            return;
        }
        if (batPercent <= 5 && !warnedCriticalBattery) {
            warnedCriticalBattery = true;
            Quickshell.execDetached([
                "notify-send", "-u", "critical",
                "Critical Battery (" + batPercent + "%)",
                "Plug in your charger immediately."
            ]);
        } else if (batPercent <= 15 && !warnedLowBattery) {
            warnedLowBattery = true;
            Quickshell.execDetached([
                "notify-send", "-u", "normal",
                "Low Battery (" + batPercent + "%)",
                "Consider connecting your charger."
            ]);
        }
    }

    Connections {
        target: SystemService
        function onTempCelsiusChanged() {
            if (SystemService.tempCelsius >= 88 && !root.warnedHighTemp) {
                root.warnedHighTemp = true;
                Quickshell.execDetached([
                    "notify-send", "-u", "critical",
                    "High CPU Temperature (" + SystemService.tempCelsius + "°C)",
                    "System temperature is running hot."
                ]);
            } else if (SystemService.tempCelsius < 75) {
                root.warnedHighTemp = false;
            }
        }
    }
}
