import QtQuick
import Quickshell
import Quickshell.Widgets
import "../config"

// Reusable list row with icon (theme app icon or Nerd Font fallback), title, and optional subtitle
Rectangle {
    id: root

    property string icon: ""
    property string appIcon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false

    signal triggered()

    implicitHeight: Properties.sizes.optionHeight
    radius: Properties.radius.medium
    color: {
        if (selected) return Properties.colors.accent;
        if (mouse.containsMouse) return Properties.colors.moduleHover;
        return "transparent";
    }

    Behavior on color {
        ColorAnimation { duration: Properties.animation.fast }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Properties.px(10)
        anchors.rightMargin: Properties.px(10)
        spacing: Properties.px(10)

        IconImage {
            id: appIconImg
            anchors.verticalCenter: parent.verticalCenter
            readonly property string resolvedSource: root.appIcon !== "" ? Quickshell.iconPath(root.appIcon, true) : ""
            visible: resolvedSource !== ""
            source: resolvedSource
            implicitSize: Properties.sizes.listIconSize
        }

        // Nerd Font fallback if no theme icon is available
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !appIconImg.visible && root.icon !== ""
            text: root.icon
            color: root.selected ? Properties.colors.textOnAccent : Properties.colors.text
            font.family: Properties.typography.iconFamily
            font.pixelSize: Properties.sizes.listIconSize - Properties.px(6)
            width: Properties.sizes.listIconSize
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Properties.sizes.listIconSize - Properties.px(16)
            spacing: Properties.px(1)

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.selected ? Properties.colors.textOnAccent : Properties.colors.text
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSizeLarge
                font.bold: root.selected
            }

            Text {
                width: parent.width
                visible: root.subtitle !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.selected ? Properties.colors.textOnAccent : Properties.colors.textMuted
                opacity: root.selected ? 0.82 : 1.0
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSizeSmall
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
