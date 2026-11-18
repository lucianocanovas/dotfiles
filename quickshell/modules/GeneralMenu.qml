import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../config"
import "../services"

// General system menu (toggled via SUPER + Space -> qs ipc call menu toggle)
PanelWindow {
    id: root

    property bool isOpen: false
    property int selectedIndex: 0

    signal openLauncher()
    signal openSettings()
    signal openPowerMenu()

    readonly property var menuOptions: [
        { id: "assistant", icon: "󰚩", title: "Assistant" },
        { id: "launcher",  icon: "󰀻", title: "App Launcher" },
        { id: "settings",  icon: "󰒓", title: "System Settings" },
        { id: "power",     icon: "⏻", title: "Power Menu" }
    ]

    function toggle() {
        isOpen = !isOpen;
        if (isOpen) {
            selectedIndex = 0;
            keyScope.forceActiveFocus();
        }
    }

    function activateOption(optionId) {
        isOpen = false;
        if (optionId === "assistant") {
            SystemService.launchAssistant();
        } else if (optionId === "launcher") {
            openLauncher();
        } else if (optionId === "settings") {
            openSettings();
        } else if (optionId === "power") {
            openPowerMenu();
        }
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
        target: "menu"
        function toggle() { root.toggle(); }
    }

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color: "#44000000"
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
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
        width: Properties.sizes.menuWidth
        height: contentCol.implicitHeight + Properties.sizes.overlayPadding * 2
        focus: true
        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.isOpen = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.selectedIndex = (root.selectedIndex + 1) % root.menuOptions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.selectedIndex = (root.selectedIndex - 1 + root.menuOptions.length) % root.menuOptions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateOption(root.menuOptions[root.selectedIndex].id);
                event.accepted = true;
            }
        }

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Properties.sizes.overlayPadding
            spacing: Properties.spacing.listGap

            Repeater {
                model: root.menuOptions

                OptionItem {
                    required property var modelData
                    required property int index

                    width: parent.width
                    icon: modelData.icon
                    title: modelData.title
                    selected: index === root.selectedIndex
                    onTriggered: root.activateOption(modelData.id)
                }
            }
        }
    }
}
