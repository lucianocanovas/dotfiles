import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../config"
import "../services"

// Right sidebar (User profile, Quick Actions, Toggles, Sliders, Media, System Monitor, Notifications)
PanelWindow {
    id: root

    property bool isOpen: false

    onIsOpenChanged: SystemService.fastPolling = isOpen

    signal openLauncher()
    signal openSettings()
    signal openPowerMenu()

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isMuted: sink?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter?.enabled ?? false
    readonly property bool wifiEnabled: Networking.wifiEnabled

    PwObjectTracker {
        objects: [root.sink]
    }

    function open() {
        isOpen = true;
        keyScope.forceActiveFocus();
    }

    function close() {
        isOpen = false;
    }

    function toggle() {
        if (isOpen) close();
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
        target: "sidebar"
        function toggle() { root.toggle(); }
    }

    // Full-screen backdrop: closes sidebar on outside click
    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.close()
    }

    Surface {
        id: keyScope
        focus: true
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: Properties.sizes.barHeight + Properties.spacing.overlayGap
        anchors.bottomMargin: Properties.spacing.overlayGap
        anchors.rightMargin: Properties.spacing.barHorizontalMargin
        width: Properties.sizes.sidebarWidth
        opacity: root.isOpen ? 1 : 0

        transform: Translate {
            x: root.isOpen ? 0 : Properties.px(32)
            Behavior on x {
                NumberAnimation { duration: Properties.animation.expressive; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        // Absorb clicks inside the sidebar
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

        Column {
            id: mainCol
            anchors.fill: parent
            anchors.margins: Properties.sizes.overlayPadding
            spacing: Properties.spacing.overlayGap

            // 1. User Profile Header (KDE Plasma style)
            Rectangle {
                id: userCard
                width: parent.width
                height: Properties.px(64)
                radius: Properties.radius.medium
                color: Properties.colors.moduleBackground

                Row {
                    anchors.fill: parent
                    anchors.margins: Properties.px(10)
                    spacing: Properties.px(12)

                    // Circular avatar (falls back to Nerd Font user icon)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Properties.px(44)
                        height: Properties.px(44)
                        radius: Properties.radius.pill
                        color: Properties.colors.barBackground
                        clip: true

                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: SystemService.avatarPath !== "" && status === Image.Ready
                            source: SystemService.avatarPath !== "" ? ("file://" + SystemService.avatarPath) : ""
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !avatarImg.visible
                            text: "󰀄"
                            color: Properties.colors.accent
                            font.family: Properties.typography.iconFamily
                            font.pixelSize: Properties.px(24)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Properties.px(56)
                        spacing: 2

                        Text {
                            width: parent.width
                            text: SystemService.fullName || SystemService.username || "User"
                            elide: Text.ElideRight
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeLarge
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: {
                                const host = SystemService.username + "@" + SystemService.hostname;
                                return SystemService.email !== "" ? (host + " • " + SystemService.email) : host;
                            }
                            elide: Text.ElideRight
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }
                    }
                }
            }

            // 2. Quick Actions (Apps, Screenshot, Settings, Power)
            Row {
                id: quickActionsRow
                width: parent.width
                spacing: Properties.spacing.listGap * 2

                Repeater {
                    model: [
                        { id: "launcher",   icon: "󰀻", label: "Apps" },
                        { id: "screenshot", icon: "󰄀", label: "Shot" },
                        { id: "settings",   icon: "󰒓", label: "Settings" },
                        { id: "power",      icon: "⏻", label: "Power" }
                    ]

                    Rectangle {
                        required property var modelData
                        width: (quickActionsRow.width - quickActionsRow.spacing * 3) / 4
                        height: Properties.px(52)
                        radius: Properties.radius.medium
                        color: actionMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                        Behavior on color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: Properties.colors.text
                                font.family: Properties.typography.iconFamily
                                font.pixelSize: Properties.px(16)
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Properties.colors.textMuted
                                font.family: Properties.typography.fontFamily
                                font.pixelSize: Properties.typography.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close();
                                if (modelData.id === "launcher") root.openLauncher();
                                else if (modelData.id === "screenshot") SystemService.takeScreenshot();
                                else if (modelData.id === "settings") root.openSettings();
                                else if (modelData.id === "power") root.openPowerMenu();
                            }
                        }
                    }
                }
            }

            // 3. Quick Toggles (Wi-Fi, Bluetooth, Do Not Disturb)
            Row {
                id: togglesRow
                width: parent.width
                spacing: Properties.spacing.listGap * 2

                Repeater {
                    model: [
                        { id: "wifi", icon: root.wifiEnabled ? "󰤨" : "󰤭", label: "Wi-Fi", active: root.wifiEnabled },
                        { id: "bt",   icon: root.btEnabled ? "󰂯" : "󰂲",   label: "BT",    active: root.btEnabled },
                        { id: "dnd",  icon: NotificationService.dnd ? "󰂛" : "󰂚", label: "DND", active: NotificationService.dnd }
                    ]

                    Rectangle {
                        required property var modelData
                        width: (togglesRow.width - togglesRow.spacing * 2) / 3
                        height: Properties.px(36)
                        radius: Properties.radius.medium
                        color: {
                            if (modelData.active) return Properties.colors.accent;
                            if (toggleMouse.containsMouse) return Properties.colors.moduleHover;
                            return Properties.colors.moduleBackground;
                        }

                        Behavior on color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: modelData.active ? Properties.colors.textOnAccent : Properties.colors.text
                                font.family: Properties.typography.iconFamily
                                font.pixelSize: Properties.px(14)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: modelData.active ? Properties.colors.textOnAccent : Properties.colors.text
                                font.family: Properties.typography.fontFamily
                                font.pixelSize: Properties.typography.fontSizeSmall
                                font.bold: modelData.active
                            }
                        }

                        MouseArea {
                            id: toggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.id === "wifi") {
                                    Networking.wifiEnabled = !Networking.wifiEnabled;
                                } else if (modelData.id === "bt" && root.btAdapter) {
                                    root.btAdapter.enabled = !root.btAdapter.enabled;
                                } else if (modelData.id === "dnd") {
                                    NotificationService.dnd = !NotificationService.dnd;
                                }
                            }
                        }
                    }
                }
            }

            // 4. Volume & Brightness Sliders
            Column {
                id: slidersCol
                width: parent.width
                spacing: Properties.spacing.listGap * 2

                SliderControl {
                    width: parent.width
                    icon: root.isMuted || root.volumePercent === 0 ? "󰖁" : "󰕾"
                    value: root.isMuted ? 0 : Math.min(100, root.volumePercent)
                    muted: root.isMuted
                    onMoved: newVal => {
                        if (root.sink?.audio) {
                            root.sink.audio.muted = false;
                            root.sink.audio.volume = newVal / 100;
                        }
                    }
                    onIconClicked: {
                        if (root.sink?.audio) {
                            root.sink.audio.muted = !root.sink.audio.muted;
                        }
                    }
                }

                SliderControl {
                    width: parent.width
                    icon: BrightnessService.icon
                    value: BrightnessService.percent
                    onMoved: newVal => BrightnessService.set(newVal)
                }
            }

            // 5. Media Controller with Album Art (MPRIS)
            Rectangle {
                id: mediaCard
                width: parent.width
                height: Properties.px(72)
                radius: Properties.radius.medium
                color: Properties.colors.moduleBackground

                Row {
                    anchors.fill: parent
                    anchors.margins: Properties.px(10)
                    spacing: Properties.px(10)

                    // Album art thumbnail
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Properties.px(52)
                        height: Properties.px(52)
                        radius: Properties.radius.small
                        color: Properties.colors.barBackground
                        clip: true

                        Image {
                            id: artImg
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: (root.player?.trackArtUrl ?? "") !== "" && status === Image.Ready
                            source: root.player?.trackArtUrl ?? ""
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !artImg.visible
                            text: "󰎈"
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.iconFamily
                            font.pixelSize: Properties.px(22)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Properties.px(62) - mediaButtons.width - Properties.px(10)
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackTitle || "Unknown Track") : "No media playing"
                            elide: Text.ElideRight
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSize
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackArtist || root.player.identity || "") : "Idle"
                            elide: Text.ElideRight
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }
                    }

                    Row {
                        id: mediaButtons
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: [
                                { action: "prev",   icon: "󰒮" },
                                { action: "toggle", icon: (root.player?.isPlaying ?? false) ? "󰏤" : "󰐊" },
                                { action: "next",   icon: "󰒭" }
                            ]

                            Rectangle {
                                required property var modelData
                                width: Properties.px(28)
                                height: Properties.px(28)
                                radius: Properties.radius.small
                                color: mediaBtnMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: root.player ? Properties.colors.text : Properties.colors.textMuted
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.px(15)
                                }

                                MouseArea {
                                    id: mediaBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.player !== null
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!root.player) return;
                                        if (modelData.action === "prev") root.player.previous();
                                        else if (modelData.action === "next") root.player.next();
                                        else root.player.togglePlaying();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 6. Mini System Monitor (CPU, RAM, Temp)
            Row {
                id: monitorRow
                width: parent.width
                spacing: Properties.spacing.listGap * 2

                Repeater {
                    model: [
                        { icon: "", label: "CPU",  value: SystemService.cpuPercent + "%" },
                        { icon: "", label: "RAM",  value: SystemService.ramPercent + "%" },
                        { icon: "", label: "Temp", value: SystemService.tempCelsius > 0 ? (SystemService.tempCelsius + "°C") : "--°C" }
                    ]

                    Rectangle {
                        required property var modelData
                        width: (monitorRow.width - monitorRow.spacing * 2) / 3
                        height: Properties.px(32)
                        radius: Properties.radius.medium
                        color: Properties.colors.moduleBackground

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: Properties.colors.accent
                                font.family: Properties.typography.iconFamily
                                font.pixelSize: Properties.px(13)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.value
                                color: Properties.colors.text
                                font.family: Properties.typography.monoFamily
                                font.pixelSize: Properties.typography.fontSizeSmall
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // 7. Notification History Header
            Item {
                id: notifHeader
                width: parent.width
                height: Properties.px(22)

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications (" + NotificationService.history.length + ")"
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: true
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: NotificationService.history.length > 0
                    implicitWidth: clearText.implicitWidth + 12
                    implicitHeight: Properties.px(22)
                    radius: Properties.radius.small
                    color: clearMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Properties.colors.accent
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.clearHistory()
                    }
                }
            }

            // 8. Notification History List
            Item {
                width: parent.width
                height: parent.height
                    - userCard.height
                    - quickActionsRow.height
                    - togglesRow.height
                    - slidersCol.height
                    - mediaCard.height
                    - monitorRow.height
                    - notifHeader.height
                    - Properties.spacing.overlayGap * 7

                ListView {
                    anchors.fill: parent
                    clip: true
                    spacing: Properties.spacing.listGap * 2
                    model: NotificationService.history

                    delegate: Rectangle {
                        id: histCard
                        required property var modelData

                        width: parent ? parent.width : 0
                        implicitHeight: histRow.implicitHeight + Properties.px(18)
                        radius: Properties.radius.medium
                        color: histMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                        Behavior on color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }

                        MouseArea {
                            id: histMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.focusApp(histCard.modelData);
                                root.close();
                            }
                        }

                        Row {
                            id: histRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Properties.px(9)
                            spacing: Properties.px(10)

                            IconImage {
                                id: histIcon
                                anchors.top: parent.top
                                readonly property string resolvedSource: histCard.modelData.appIcon
                                    ? Quickshell.iconPath(histCard.modelData.appIcon, true)
                                    : ""
                                visible: resolvedSource !== ""
                                source: resolvedSource
                                implicitSize: Properties.px(24)
                            }

                            Text {
                                anchors.top: parent.top
                                visible: !histIcon.visible
                                text: "󰂚"
                                color: Properties.colors.textMuted
                                font.family: Properties.typography.iconFamily
                                font.pixelSize: Properties.px(18)
                                width: Properties.px(24)
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Column {
                                width: parent.width - Properties.px(56)
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: histCard.modelData.summary || histCard.modelData.appName || "Notification"
                                    elide: Text.ElideRight
                                    color: Properties.colors.text
                                    font.family: Properties.typography.fontFamily
                                    font.pixelSize: Properties.typography.fontSize
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width
                                    visible: text !== ""
                                    text: (histCard.modelData.body ?? "").replace(/\n+/g, " ").trim()
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: Properties.colors.textMuted
                                    font.family: Properties.typography.fontFamily
                                    font.pixelSize: Properties.typography.fontSizeSmall
                                }
                            }

                            Rectangle {
                                anchors.top: parent.top
                                width: Properties.px(20)
                                height: Properties.px(20)
                                radius: Properties.radius.small
                                color: delMouse.containsMouse ? Properties.colors.barBackground : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: Properties.colors.textMuted
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.typography.fontSize
                                }

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.closeNotification(histCard.modelData)
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: NotificationService.history.length === 0
                    text: "No notifications"
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSize
                }
            }
        }
    }
}
