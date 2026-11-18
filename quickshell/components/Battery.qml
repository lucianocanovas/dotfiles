import QtQuick
import Quickshell.Services.UPower
import "../config"

// Battery indicator using UPower with Nerd Font icons
BarPill {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property int percent: Math.round((bat?.percentage ?? 0) * 100)
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
                                  || bat?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: bat?.state === UPowerDeviceState.FullyCharged

    icon: {
        if (charging) return "󰂄";
        if (full || percent >= 95) return "󰁹";
        if (percent >= 80) return "󰂁";
        if (percent >= 60) return "󰁿";
        if (percent >= 40) return "󰁽";
        if (percent >= 20) return "󰁻";
        return "󰂎";
    }
    text: percent + "%"
    monospace: true
    contentColor: {
        if (charging) return Properties.colors.success;
        if (percent <= 15) return Properties.colors.error;
        return Properties.colors.text;
    }
}
