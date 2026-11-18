import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../config"

// Compact Windows/KDE-style window switcher (confirms on Alt/Super release)
PanelWindow {
    id: root

    property bool isOpen: false
    property int selectedIndex: 0
    readonly property var windows: Hyprland.toplevels.values
    readonly property var selectedWindow: (selectedIndex >= 0 && selectedIndex < windows.length)
        ? windows[selectedIndex]
        : null

    function openAndStep(step) {
        if (windows.length === 0) {
            isOpen = false;
            return;
        }
        if (!isOpen) {
            isOpen = true;
            selectedIndex = windows.length > 1 ? 1 : 0;
        } else {
            selectedIndex = (selectedIndex + step + windows.length) % windows.length;
        }
        keyScope.forceActiveFocus();
    }

    function focusSelected() {
        if (!isOpen) return;
        if (selectedIndex >= 0 && selectedIndex < windows.length) {
            const win = windows[selectedIndex];
            const addr = win.address.startsWith("0x") ? win.address : ("0x" + win.address);
            const cmd = Hyprland.usingLua
                ? "hl.dsp.focus({ window = \"address:" + addr + "\" })"
                : "focuswindow address:" + addr;
            Hyprland.dispatch(cmd);
        }
        isOpen = false;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: isOpen || keyScope.opacity > 0
    focusable: isOpen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    IpcHandler {
        target: "alttab"
        function next() { root.openAndStep(1); }
        function prev() { root.openAndStep(-1); }
        function confirm() { root.focusSelected(); }
        function toggle() {
            if (root.isOpen) root.isOpen = false;
            else root.openAndStep(0);
        }
    }

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color: "#33000000"
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
        }
    }

    // Close on outside click
    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.isOpen = false
    }

    Surface {
        id: keyScope
        anchors.centerIn: parent
        width: Math.max(Properties.px(220), iconsRow.implicitWidth + Properties.sizes.overlayPadding * 2)
        height: mainCol.implicitHeight + Properties.sizes.overlayPadding * 2
        focus: true
        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.isOpen = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.openAndStep(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.openAndStep(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.focusSelected();
                event.accepted = true;
            }
        }

        // Confirm selection and close when releasing Alt or Super
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt
                    || event.key === Qt.Key_Meta
                    || event.key === Qt.Key_Super_L
                    || event.key === Qt.Key_Super_R) {
                root.focusSelected();
                event.accepted = true;
            }
        }

        Column {
            id: mainCol
            anchors.centerIn: parent
            spacing: Properties.px(10)

            Row {
                id: iconsRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Properties.px(8)

                Repeater {
                    model: root.windows

                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property string appClass: modelData.lastIpcObject?.class ?? ""
                        readonly property var entry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
                        readonly property string iconName: entry?.icon ?? appClass.toLowerCase()
                        readonly property string iconSource: iconName !== "" ? Quickshell.iconPath(iconName, true) : ""

                        implicitWidth: Properties.sizes.altTabTileSize
                        implicitHeight: Properties.sizes.altTabTileSize
                        radius: Properties.radius.medium
                        color: isSelected
                            ? Properties.colors.moduleBackground
                            : (mouse.containsMouse ? Properties.colors.moduleHover : "transparent")
                        border.width: Properties.px(2)
                        border.color: isSelected ? Properties.colors.accent : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }

                        IconImage {
                            id: appIconImg
                            anchors.centerIn: parent
                            visible: tile.iconSource !== ""
                            source: tile.iconSource
                            implicitSize: Properties.sizes.altTabIconSize
                        }

                        // Fallback Nerd Font icon when no theme icon is available
                        Text {
                            anchors.centerIn: parent
                            visible: !appIconImg.visible
                            text: "󰖯"
                            color: Properties.colors.text
                            font.family: Properties.typography.iconFamily
                            font.pixelSize: Properties.px(26)
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = tile.index;
                                root.focusSelected();
                            }
                        }
                    }
                }
            }

            // Selected window title & workspace hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(Properties.px(420), Math.max(Properties.px(180), iconsRow.implicitWidth))
                horizontalAlignment: Text.AlignHCenter
                text: root.selectedWindow
                    ? (root.selectedWindow.title || root.selectedWindow.lastIpcObject?.class || "Window")
                    : ""
                elide: Text.ElideRight
                color: Properties.colors.textMuted
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSizeSmall
            }
        }
    }
}
