import QtQuick
import Quickshell.Networking
import "../config"

// Wi-Fi indicator using Quickshell.Networking (icon + connected SSID)
BarPill {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var activeNetwork: wifiDevice?.networks?.values.find(n => n.connected) ?? null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool connected: wifiDevice?.state === ConnectionState.Connected
    readonly property string networkName: activeNetwork?.name ?? ""

    icon: {
        if (!enabled) return "󰤭";
        if (connected) return "󰤨";
        return "󰤯";
    }
    text: (enabled && connected && networkName !== "") ? networkName : ""
    monospace: false
    contentColor: enabled ? Properties.colors.text : Properties.colors.textMuted

    onRightClicked: Networking.wifiEnabled = !Networking.wifiEnabled
}
