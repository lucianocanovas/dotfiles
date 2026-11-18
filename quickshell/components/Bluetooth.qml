import QtQuick
import Quickshell.Bluetooth
import "../config"

// Bluetooth status indicator using Quickshell.Bluetooth
BarPill {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    icon: enabled ? "󰂯" : "󰂲"
    contentColor: enabled ? Properties.colors.text : Properties.colors.textMuted

    onRightClicked: {
        if (root.adapter) {
            root.adapter.enabled = !root.adapter.enabled;
        }
    }
}
