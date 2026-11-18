import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../config"

// Subtle active application logo indicator for the top bar
Rectangle {
    id: root

    readonly property var activeWin: Hyprland.activeToplevel
        ?? Hyprland.toplevels.values.find(t => t.activated)
        ?? null

    readonly property string appClass: activeWin?.lastIpcObject?.class ?? activeWin?.wayland?.appId ?? ""
    readonly property bool hasWindow: activeWin !== null && appClass !== ""
    readonly property var entry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string iconName: entry?.icon ?? appClass.toLowerCase()
    readonly property string iconSource: iconName !== "" ? Quickshell.iconPath(iconName, true) : ""

    visible: opacity > 0
    opacity: hasWindow ? 0.9 : 0.0
    implicitWidth: hasWindow ? Properties.sizes.moduleHeight : 0
    implicitHeight: Properties.sizes.moduleHeight
    radius: Properties.radius.module
    color: Properties.colors.moduleBackground
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
    }

    IconImage {
        id: appIcon
        anchors.centerIn: parent
        visible: root.iconSource !== ""
        source: root.iconSource
        implicitSize: Properties.px(16)
    }

    Text {
        anchors.centerIn: parent
        visible: !appIcon.visible && root.hasWindow
        text: "󰣆"
        color: Properties.colors.textMuted
        font.family: Properties.typography.iconFamily
        font.pixelSize: Properties.px(14)
    }
}
