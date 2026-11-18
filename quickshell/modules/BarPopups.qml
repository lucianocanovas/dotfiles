import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../components/popups"
import "../config"

// Manages dropdown popups positioned directly below each clicked bar button
PanelWindow {
    id: root

    property bool isOpen: false
    property string activePopup: ""
    property real anchorCenterX: 0

    function toggle(name, centerX) {
        if (isOpen && activePopup === name) {
            close();
        } else {
            anchorCenterX = centerX ?? 0;
            activePopup = name;
            isOpen = true;
            keyScope.forceActiveFocus();
        }
    }

    function close() {
        isOpen = false;
    }

    readonly property string popupSource: {
        if (activePopup === "calendar")   return "../components/popups/CalendarPopup.qml";
        if (activePopup === "weather")    return "../components/popups/WeatherPopup.qml";
        if (activePopup === "brightness") return "../components/popups/BrightnessPopup.qml";
        if (activePopup === "audio")      return "../components/popups/AudioPopup.qml";
        if (activePopup === "wifi")       return "../components/popups/WifiPopup.qml";
        if (activePopup === "bluetooth")  return "../components/popups/BluetoothPopup.qml";
        if (activePopup === "battery")    return "../components/popups/BatteryPopup.qml";
        return "";
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

    // Full-screen backdrop: closes popup on outside click without hitting windows underneath
    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.close()
    }

    Surface {
        id: keyScope
        focus: true
        clip: true
        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1.0 : 0.96
        transformOrigin: Item.Top

        transform: Translate {
            y: root.isOpen ? 0 : -Properties.px(10)
            Behavior on y {
                NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        width: root.activePopup === "calendar" ? Properties.sizes.calendarPopupWidth : Properties.sizes.popupWidth
        height: contentLoader.implicitHeight + Properties.sizes.overlayPadding * 2

        // Position centered under the clicked bar button, clamped to screen margins
        x: Math.max(
            Properties.spacing.barHorizontalMargin,
            Math.min(root.anchorCenterX - width / 2, root.width - width - Properties.spacing.barHorizontalMargin)
        )
        y: Properties.sizes.barHeight + Properties.spacing.overlayGap

        Behavior on x {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        // Absorb clicks inside the popup so they don't trigger the backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }

        Loader {
            id: contentLoader
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Properties.sizes.overlayPadding
            source: root.popupSource
        }
    }
}
