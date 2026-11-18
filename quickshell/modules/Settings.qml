import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../components/popups"
import "../components/settings"
import "../config"

// System Settings window (toggled via Sidebar, GeneralMenu, or qs ipc call settings toggle)
PanelWindow {
    id: root

    property bool isOpen: false
    property string activeTab: "display"

    readonly property var tabs: [
        { id: "display",   icon: "󰍹", title: "Display",   source: "../components/settings/DisplayTab.qml" },
        { id: "theme",     icon: "󰏘", title: "Theme",     source: "../components/settings/ThemeTab.qml" },
        { id: "hyprland",  icon: "", title: "Hyprland",  source: "../components/settings/HyprlandTab.qml" },
        { id: "network",   icon: "󰤨", title: "Network",   source: "../components/popups/WifiPopup.qml" },
        { id: "bluetooth", icon: "󰂯", title: "Bluetooth", source: "../components/popups/BluetoothPopup.qml" },
        { id: "audio",     icon: "󰕾", title: "Audio",     source: "../components/popups/AudioPopup.qml" },
        { id: "power",     icon: "⏻", title: "Power",     source: "../components/settings/PowerTab.qml" },
        { id: "keybinds",  icon: "󰌌", title: "Keybinds",  source: "../components/settings/KeybindsTab.qml" },
        { id: "assistant", icon: "󰚩", title: "Assistant", source: "../components/settings/AssistantTab.qml" },
        { id: "user",      icon: "󰀄", title: "User",      source: "../components/settings/UserTab.qml" }
    ]

    readonly property string activeSource: {
        const match = tabs.find(t => t.id === activeTab);
        return match ? match.source : tabs[0].source;
    }

    function open(tabId) {
        if (tabId) activeTab = tabId;
        isOpen = true;
        keyScope.forceActiveFocus();
    }

    function toggle() {
        if (isOpen) isOpen = false;
        else open();
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
        target: "settings"
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
        width: Properties.sizes.settingsWidth
        height: Properties.sizes.settingsHeight
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
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: Properties.sizes.overlayPadding
            spacing: Properties.spacing.overlayGap

            // Left category sidebar
            Column {
                width: Properties.sizes.settingsNavWidth
                height: parent.height
                spacing: Properties.spacing.listGap

                Item {
                    width: parent.width
                    height: Properties.px(28)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 8
                        text: "System Settings"
                        color: Properties.colors.textMuted
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                        font.bold: true
                    }
                }

                Repeater {
                    model: root.tabs

                    OptionItem {
                        required property var modelData
                        width: parent.width
                        height: Properties.px(38)
                        icon: modelData.icon
                        title: modelData.title
                        selected: root.activeTab === modelData.id
                        onTriggered: root.activeTab = modelData.id
                    }
                }
            }

            // Vertical divider
            Rectangle {
                width: Properties.sizes.borderWidth
                height: parent.height
                color: Properties.colors.border
            }

            // Right scrollable content area
            Flickable {
                id: contentFlick
                width: parent.width - Properties.sizes.settingsNavWidth - Properties.sizes.borderWidth - Properties.spacing.overlayGap * 2
                height: parent.height
                clip: true
                contentWidth: width
                contentHeight: root.activeTab === "keybinds" ? height : (tabLoader.item ? tabLoader.item.implicitHeight : height)

                Loader {
                    id: tabLoader
                    width: contentFlick.width
                    height: root.activeTab === "keybinds" ? contentFlick.height : implicitHeight
                    source: root.activeSource
                }
            }
        }
    }
}
