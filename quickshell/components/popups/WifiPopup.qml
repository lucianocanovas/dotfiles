import QtQuick
import Quickshell
import Quickshell.Networking
import "../../components"
import "../../config"

// Wi-Fi network manager popup
Column {
    id: root

    property string passwordTargetSsid: ""
    property bool showPasswordPrompt: false

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property var sortedNetworks: {
        if (!wifiDevice || !wifiEnabled) return [];
        const seen = new Set();
        const unique = [];
        for (const n of wifiDevice.networks.values) {
            if (!n.name || seen.has(n.name)) continue;
            seen.add(n.name);
            unique.push(n);
        }
        return unique.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
        });
    }

    function signalIcon(strength, connected) {
        if (connected) return "󰤨";
        if (strength >= 75) return "󰤨";
        if (strength >= 50) return "󰤥";
        if (strength >= 25) return "󰤢";
        return "󰤟";
    }

    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Header: Wi-Fi toggle + Scan button
    Item {
        width: parent.width
        height: Properties.px(28)

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi Networks"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Scan button
            Rectangle {
                visible: root.wifiEnabled && root.wifiDevice !== null
                width: Properties.px(26)
                height: Properties.px(26)
                radius: Properties.radius.small
                color: scanMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    color: (root.wifiDevice?.scannerEnabled ?? false) ? Properties.colors.accent : Properties.colors.text
                    font.family: Properties.typography.iconFamily
                    font.pixelSize: Properties.px(14)
                }

                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.wifiDevice) {
                            root.wifiDevice.scannerEnabled = true;
                        }
                    }
                }
            }

            // Enable/Disable Wi-Fi toggle
            Rectangle {
                implicitWidth: toggleText.implicitWidth + 16
                implicitHeight: Properties.px(26)
                radius: Properties.radius.small
                color: root.wifiEnabled ? Properties.colors.accent : Properties.colors.moduleBackground

                Text {
                    id: toggleText
                    anchors.centerIn: parent
                    text: root.wifiEnabled ? "On" : "Off"
                    color: root.wifiEnabled ? Properties.colors.textOnAccent : Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }
        }
    }

    // Inline password prompt for new secured networks
    Rectangle {
        visible: root.showPasswordPrompt
        width: parent.width
        height: Properties.px(42)
        radius: Properties.radius.medium
        color: Properties.colors.moduleBackground
        border.color: Properties.colors.accent
        border.width: Properties.sizes.borderWidth

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            TextInput {
                id: passInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Properties.px(64)
                echoMode: TextInput.Password
                color: Properties.colors.text
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
                clip: true

                Keys.onReturnPressed: connectBtnMouse.clicked(null)
                Keys.onEscapePressed: root.showPasswordPrompt = false
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Properties.px(54)
                height: Properties.px(26)
                radius: Properties.radius.small
                color: Properties.colors.accent

                Text {
                    anchors.centerIn: parent
                    text: "Join"
                    color: Properties.colors.textOnAccent
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: true
                }

                MouseArea {
                    id: connectBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (passInput.text !== "") {
                            Quickshell.execDetached([
                                "nmcli", "device", "wifi", "connect",
                                root.passwordTargetSsid, "password", passInput.text
                            ]);
                            passInput.text = "";
                            root.showPasswordPrompt = false;
                        }
                    }
                }
            }
        }
    }

    // Network list
    Item {
        width: parent.width
        height: root.wifiEnabled ? Math.min(Properties.px(240), Math.max(Properties.px(60), netList.contentHeight)) : Properties.px(48)

        ListView {
            id: netList
            anchors.fill: parent
            visible: root.wifiEnabled
            clip: true
            spacing: Properties.spacing.listGap
            model: root.sortedNetworks

            delegate: OptionItem {
                required property var modelData

                width: netList.width
                height: Properties.px(38)
                icon: root.signalIcon(modelData.signalStrength ?? 0, modelData.connected)
                title: modelData.name
                subtitle: modelData.connected ? "Connected" : (modelData.known ? "Saved" : "")
                selected: modelData.connected
                onTriggered: {
                    if (modelData.connected) {
                        modelData.disconnect();
                    } else if (modelData.known) {
                        modelData.connect();
                    } else {
                        root.passwordTargetSsid = modelData.name;
                        root.showPasswordPrompt = true;
                        passInput.forceActiveFocus();
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.wifiEnabled || root.sortedNetworks.length === 0
            text: root.wifiEnabled ? "No networks found" : "Wi-Fi is turned off"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
        }
    }
}
