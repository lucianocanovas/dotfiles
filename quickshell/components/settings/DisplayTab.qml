import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../components"
import "../../config"
import "../../services"

// Display & Scale settings tab (Quickshell UI scale, Hyprland monitor scale, Brightness)
Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap * 1.5

    // 1. Quickshell UI Scale
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Quickshell UI Scale"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Row {
            width: parent.width
            spacing: Properties.spacing.listGap * 2

            Repeater {
                model: [0.85, 1.0, 1.15, 1.25]

                Rectangle {
                    required property real modelData
                    readonly property bool active: Math.abs(Properties.scale - modelData) < 0.01

                    width: (parent.width - Properties.spacing.listGap * 6) / 4
                    height: Properties.px(34)
                    radius: Properties.radius.medium
                    color: active
                        ? Properties.colors.accent
                        : (qsMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground)

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "x"
                        color: active ? Properties.colors.textOnAccent : Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSize
                        font.bold: active
                    }

                    MouseArea {
                        id: qsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Properties.setScale(modelData)
                    }
                }
            }
        }
    }

    // 2. Hyprland Monitors
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Hyprland Monitors"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: Hyprland.monitors.values

            Rectangle {
                id: monCard
                required property var modelData

                width: parent.width
                implicitHeight: monCol.implicitHeight + Properties.px(20)
                radius: Properties.radius.medium
                color: Properties.colors.moduleBackground

                Column {
                    id: monCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Properties.px(10)
                    spacing: Properties.spacing.listGap * 2

                    Item {
                        width: parent.width
                        height: Properties.px(22)

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍹 " + monCard.modelData.name
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSize
                            font.bold: true
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: monCard.modelData.width + "x" + monCard.modelData.height
                                + " • " + Number(monCard.modelData.scale).toFixed(2) + "x"
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Properties.spacing.listGap * 2

                        Repeater {
                            model: [1.0, 1.2, 1.25, 1.5]

                            Rectangle {
                                required property real modelData
                                readonly property bool active: Math.abs(monCard.modelData.scale - modelData) < 0.02

                                width: (parent.width - Properties.spacing.listGap * 6) / 4
                                height: Properties.px(30)
                                radius: Properties.radius.small
                                color: active
                                    ? Properties.colors.accent
                                    : (monScaleMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.barBackground)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "x"
                                    color: active ? Properties.colors.textOnAccent : Properties.colors.text
                                    font.family: Properties.typography.fontFamily
                                    font.pixelSize: Properties.typography.fontSizeSmall
                                    font.bold: active
                                }

                                MouseArea {
                                    id: monScaleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Properties.saveMonitorScale(monCard.modelData.name, modelData);
                                        Hyprland.refreshMonitors();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 3. Brightness
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Screen Brightness"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        SliderControl {
            width: parent.width
            icon: BrightnessService.icon
            value: BrightnessService.percent
            onMoved: newVal => BrightnessService.set(newVal)
        }
    }
}
