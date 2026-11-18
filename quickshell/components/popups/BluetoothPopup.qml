import QtQuick
import Quickshell.Bluetooth
import "../../components"
import "../../config"

// Bluetooth device manager popup
Column {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    readonly property var sortedDevices: {
        if (!adapter || !btEnabled) return [];
        const list = adapter.devices.values.filter(d => (d.deviceName || d.name || "") !== "");
        return list.slice().sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return (a.deviceName || a.name).localeCompare(b.deviceName || b.name);
        });
    }

    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Header: Bluetooth toggle + Scan button
    Item {
        width: parent.width
        height: Properties.px(28)

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth Devices"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                visible: root.btEnabled && root.adapter !== null
                width: Properties.px(26)
                height: Properties.px(26)
                radius: Properties.radius.small
                color: scanMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    color: root.discovering ? Properties.colors.accent : Properties.colors.text
                    font.family: Properties.typography.iconFamily
                    font.pixelSize: Properties.px(14)
                }

                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.adapter) {
                            root.adapter.discovering = !root.adapter.discovering;
                        }
                    }
                }
            }

            Rectangle {
                implicitWidth: toggleText.implicitWidth + 16
                implicitHeight: Properties.px(26)
                radius: Properties.radius.small
                color: root.btEnabled ? Properties.colors.accent : Properties.colors.moduleBackground

                Text {
                    id: toggleText
                    anchors.centerIn: parent
                    text: root.btEnabled ? "On" : "Off"
                    color: root.btEnabled ? Properties.colors.textOnAccent : Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.adapter) {
                            root.adapter.enabled = !root.adapter.enabled;
                        }
                    }
                }
            }
        }
    }

    // Device list
    Item {
        width: parent.width
        height: root.btEnabled ? Math.min(Properties.px(240), Math.max(Properties.px(60), btList.contentHeight)) : Properties.px(48)

        ListView {
            id: btList
            anchors.fill: parent
            visible: root.btEnabled
            clip: true
            spacing: Properties.spacing.listGap
            model: root.sortedDevices

            delegate: OptionItem {
                required property var modelData

                width: btList.width
                height: Properties.px(38)
                icon: modelData.connected ? "󰂱" : "󰂯"
                title: modelData.deviceName || modelData.name || "Unknown Device"
                subtitle: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                selected: modelData.connected
                onTriggered: {
                    if (modelData.connected) {
                        modelData.disconnect();
                    } else {
                        modelData.connect();
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.btEnabled || root.sortedDevices.length === 0
            text: root.btEnabled ? "No devices found" : "Bluetooth is turned off"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
        }
    }
}
