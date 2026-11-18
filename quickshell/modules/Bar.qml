import QtQuick
import Quickshell
import "../components"
import "../config"

// Top status bar anchored across the full width of the screen
PanelWindow {
    id: root

    property bool sidebarOpen: false
    property string activePopup: ""

    signal toggleSidebar()
    signal togglePopup(string name, real centerX)

    function triggerPopup(name, item) {
        const centerX = item.mapToItem(null, 0, 0).x + item.width / 2;
        togglePopup(name, centerX);
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Properties.sizes.barHeight
    color: Properties.colors.barBackground

    Item {
        anchors.fill: parent
        anchors.leftMargin: Properties.spacing.barHorizontalMargin
        anchors.rightMargin: Properties.spacing.barHorizontalMargin

        // Left section: clock & subtle active window logo
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Properties.spacing.sectionSpacing

            Clock {
                id: clockBtn
                active: root.activePopup === "calendar"
                onClicked: root.triggerPopup("calendar", clockBtn)
            }

            ActiveWindow {}
        }

        // Center section: workspaces
        Row {
            anchors.centerIn: parent
            spacing: Properties.spacing.sectionSpacing

            Workspaces {}
        }

        // Right section: system status indicators and sidebar menu button
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Properties.spacing.sectionSpacing

            Weather {
                id: weatherBtn
                active: root.activePopup === "weather"
                onClicked: root.triggerPopup("weather", weatherBtn)
            }
            Brightness {
                id: brightnessBtn
                active: root.activePopup === "brightness"
                onClicked: root.triggerPopup("brightness", brightnessBtn)
            }
            Volume {
                id: volumeBtn
                active: root.activePopup === "audio"
                onClicked: root.triggerPopup("audio", volumeBtn)
            }
            Wifi {
                id: wifiBtn
                active: root.activePopup === "wifi"
                onClicked: root.triggerPopup("wifi", wifiBtn)
            }
            Bluetooth {
                id: btBtn
                active: root.activePopup === "bluetooth"
                onClicked: root.triggerPopup("bluetooth", btBtn)
            }
            Battery {
                id: batteryBtn
                active: root.activePopup === "battery"
                onClicked: root.triggerPopup("battery", batteryBtn)
            }
            MenuButton {
                active: root.sidebarOpen
                onClicked: root.toggleSidebar()
            }
        }
    }
}
