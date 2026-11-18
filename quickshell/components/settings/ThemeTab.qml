import QtQuick
import "../../config"
import "../../services"

// Theme presets, typography mode, accent color, and wallpaper customization
Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap * 1.5

    // 1. Typography Style (Hybrid Sans+Mono vs Full Monospace)
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Typography Style"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Row {
            width: parent.width
            spacing: Properties.spacing.listGap * 2

            Repeater {
                model: [
                    { id: "hybrid", title: "Hybrid (Sans UI + Mono Data)", icon: "󰛖" },
                    { id: "mono",   title: "Full Mono (JetBrains Mono)",   icon: "󰆍" }
                ]

                Rectangle {
                    required property var modelData
                    readonly property bool isActive: Properties.fontMode === modelData.id

                    width: (parent.width - Properties.spacing.listGap * 2) / 2
                    height: Properties.px(38)
                    radius: Properties.radius.medium
                    color: isActive
                        ? Properties.colors.accent
                        : (fontMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground)

                    Behavior on color {
                        ColorAnimation { duration: Properties.animation.fast }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Properties.px(8)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            color: isActive ? Properties.colors.textOnAccent : Properties.colors.text
                            font.family: Properties.typography.iconFamily
                            font.pixelSize: Properties.typography.iconSize
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            color: isActive ? Properties.colors.textOnAccent : Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                            font.bold: isActive
                        }
                    }

                    MouseArea {
                        id: fontMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Properties.setFontMode(modelData.id)
                    }
                }
            }
        }
    }

    // 2. Theme Presets
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Color Theme"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: Properties.themePresets

            Rectangle {
                required property var modelData
                readonly property bool isActive: Properties.colors.barBackground.toString().toUpperCase() === modelData.barBackground.toUpperCase()

                width: parent.width
                height: Properties.px(42)
                radius: Properties.radius.medium
                color: isActive
                    ? Properties.colors.moduleHover
                    : (themeMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground)
                border.width: isActive ? 2 : 1
                border.color: isActive ? Properties.colors.accent : Properties.colors.border

                Behavior on color {
                    ColorAnimation { duration: Properties.animation.fast }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Properties.px(12)
                    anchors.rightMargin: Properties.px(12)
                    spacing: Properties.px(10)

                    // Color swatch preview
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Properties.px(4)

                        Rectangle {
                            width: Properties.px(14)
                            height: Properties.px(14)
                            radius: Properties.radius.pill
                            color: modelData.barBackground
                            border.width: 1
                            border.color: Properties.colors.border
                        }
                        Rectangle {
                            width: Properties.px(14)
                            height: Properties.px(14)
                            radius: Properties.radius.pill
                            color: modelData.accent
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSize
                        font.bold: isActive
                    }
                }

                MouseArea {
                    id: themeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Properties.applyTheme(modelData)
                }
            }
        }
    }

    // 3. Accent Color Swatches
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Text {
            text: "Accent Color"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Row {
            spacing: Properties.px(10)

            Repeater {
                model: Properties.accentPresets

                Rectangle {
                    required property string modelData
                    readonly property bool isActive: Properties.colors.accent.toString().toUpperCase() === modelData.toUpperCase()

                    width: Properties.px(30)
                    height: Properties.px(30)
                    radius: Properties.radius.pill
                    color: modelData
                    scale: accentMouse.containsMouse || isActive ? 1.08 : 1.0
                    border.width: isActive ? 2 : 0
                    border.color: Properties.colors.text

                    Behavior on scale {
                        NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        id: accentMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Properties.setAccent(modelData)
                    }
                }
            }
        }
    }

    // 4. Wallpaper Picker
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 1.5

        Item {
            width: parent.width
            height: Properties.px(24)

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpaper"
                color: Properties.colors.textMuted
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSizeSmall
                font.bold: true
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: browseLabel.implicitWidth + Properties.px(14)
                implicitHeight: Properties.px(24)
                radius: Properties.radius.small
                color: browseMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                Text {
                    id: browseLabel
                    anchors.centerIn: parent
                    text: "Browse..."
                    color: Properties.colors.accent
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }

                MouseArea {
                    id: browseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemService.pickWallpaper()
                }
            }
        }

        Grid {
            width: parent.width
            columns: 3
            spacing: Properties.spacing.listGap * 2

            Repeater {
                model: SystemService.wallpapers

                Rectangle {
                    required property string modelData
                    readonly property bool isActive: SystemService.currentWallpaper === modelData

                    width: (parent.width - Properties.spacing.listGap * 4) / 3
                    height: Properties.px(84)
                    radius: Properties.radius.medium
                    color: Properties.colors.moduleBackground
                    border.width: isActive ? 2 : 1
                    border.color: isActive ? Properties.colors.accent : Properties.colors.border
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: isActive ? 2 : 1
                        fillMode: Image.PreserveAspectCrop
                        source: "file://" + modelData
                        asynchronous: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.setWallpaper(modelData)
                    }
                }
            }
        }
    }
}
