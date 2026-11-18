import QtQuick
import Quickshell.Hyprland
import "../config"

// Hyprland workspace switcher (fixed to 5 workspaces, rendered as animated pills/dots)
Rectangle {
    id: root

    implicitWidth: dotsRow.implicitWidth + Properties.sizes.modulePadding
    implicitHeight: Properties.sizes.moduleHeight
    radius: Properties.radius.module
    color: Properties.colors.moduleBackground

    function switchWorkspace(wsId) {
        const clamped = Math.max(1, Math.min(5, wsId));
        const cmd = Hyprland.usingLua
            ? "hl.dsp.focus({ workspace = " + clamped + " })"
            : "workspace " + clamped;
        Hyprland.dispatch(cmd);
    }

    Row {
        id: dotsRow
        anchors.centerIn: parent
        spacing: Properties.spacing.workspaceSpacing

        Repeater {
            model: 5

            Item {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                readonly property bool isOccupied: Hyprland.workspaces.values.some(w => w.id === wsId)

                implicitWidth: dot.width + Properties.px(4)
                implicitHeight: Properties.sizes.moduleHeight

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    height: Properties.sizes.workspaceDotHeight
                    width: isActive ? Properties.sizes.workspaceDotActiveWidth : Properties.sizes.workspaceDotWidth
                    radius: Properties.radius.pill

                    color: isActive
                        ? Properties.colors.accent
                        : (dotMouse.containsMouse
                            ? Properties.colors.text
                            : (isOccupied ? Properties.colors.text : Properties.colors.textMuted))
                    opacity: (!isActive && !isOccupied && !dotMouse.containsMouse) ? 0.55 : 1.0

                    Behavior on width {
                        NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Properties.animation.fast }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Properties.animation.fast }
                    }
                }

                MouseArea {
                    id: dotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switchWorkspace(wsId)
                    onWheel: wheel => {
                        const current = Hyprland.focusedWorkspace?.id ?? 1;
                        if (wheel.angleDelta.y > 0) root.switchWorkspace(current - 1);
                        else if (wheel.angleDelta.y < 0) root.switchWorkspace(current + 1);
                    }
                }
            }
        }
    }
}
