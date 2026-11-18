import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../components"
import "../config"
import "../services"

// Session lock screen with blurred wallpaper, clock, PAM unlock, and MPRIS media controls
Scope {
    id: root

    property string errorMessage: ""
    property bool authenticating: false

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    function lock() {
        errorMessage = "";
        authenticating = false;
        sessionLock.locked = true;
    }

    function submitPassword(password) {
        if (authenticating || password === "") return;
        errorMessage = "";
        authenticating = true;
        if (!pam.start()) {
            authenticating = false;
            errorMessage = "Authentication failed to start";
        } else {
            pendingPassword = password;
        }
    }

    property string pendingPassword: ""

    IpcHandler {
        target: "lock"
        function lock() { root.lock(); }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PamContext {
        id: pam
        user: SystemService.username

        onResponseRequiredChanged: {
            if (responseRequired && root.pendingPassword !== "") {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }

        onCompleted: result => {
            root.authenticating = false;
            root.pendingPassword = "";
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                root.errorMessage = "";
            } else {
                root.errorMessage = "Incorrect password";
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: lockSurface

            // Blurred wallpaper background
            Item {
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: Properties.colors.barBackground
                }

                Image {
                    id: bgImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    source: SystemService.currentWallpaper !== "" ? ("file://" + SystemService.currentWallpaper) : ""
                }

                MultiEffect {
                    anchors.fill: parent
                    source: bgImg
                    visible: bgImg.status === Image.Ready
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                }

                // Subtle dark scrim for contrast
                Rectangle {
                    anchors.fill: parent
                    color: "#77000000"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: passInput.forceActiveFocus()
                }
            }

            // Clock & Date (top center)
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Properties.px(72)
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Properties.colors.text
                    font.family: Properties.typography.monoFamily
                    font.pixelSize: Properties.px(72)
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.locale("en_US").toString(clock.date, "dddd, MMMM d")
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.px(18)
                }
            }

            // Unlock card (center)
            Surface {
                anchors.centerIn: parent
                width: Properties.px(320)
                height: unlockCol.implicitHeight + Properties.sizes.overlayPadding * 2

                Column {
                    id: unlockCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Properties.sizes.overlayPadding
                    spacing: Properties.spacing.overlayGap

                    // Avatar
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Properties.px(68)
                        height: Properties.px(68)
                        radius: Properties.radius.pill
                        color: Properties.colors.moduleBackground
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
                            font.pixelSize: Properties.px(32)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: SystemService.fullName || SystemService.username || "User"
                        color: Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeLarge
                        font.bold: true
                    }

                    // Password input
                    Rectangle {
                        width: parent.width
                        height: Properties.sizes.searchHeight
                        radius: Properties.radius.medium
                        color: Properties.colors.moduleBackground
                        border.width: Properties.sizes.borderWidth
                        border.color: root.errorMessage !== ""
                            ? Properties.colors.error
                            : (passInput.activeFocus ? Properties.colors.accent : Properties.colors.border)

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            focus: true
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSize

                            Component.onCompleted: {
                                text = "";
                                forceActiveFocus();
                            }

                            Connections {
                                target: sessionLock
                                function onLockedChanged() {
                                    if (sessionLock.locked) {
                                        passInput.text = "";
                                        passInput.forceActiveFocus();
                                    }
                                }
                            }

                            onAccepted: {
                                const val = text;
                                text = "";
                                root.submitPassword(val);
                            }
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: root.authenticating ? "Unlocking..." : "Password"
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSize
                            visible: passInput.text.length === 0
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.errorMessage !== ""
                        text: root.errorMessage
                        color: Properties.colors.error
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                    }
                }
            }

            // Media controls (bottom center, shown when a player is active)
            Surface {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Properties.px(48)
                visible: root.player !== null
                width: Properties.px(340)
                height: Properties.px(68)

                Row {
                    anchors.fill: parent
                    anchors.margins: Properties.px(10)
                    spacing: Properties.px(10)

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Properties.px(48)
                        height: Properties.px(48)
                        radius: Properties.radius.small
                        color: Properties.colors.moduleBackground
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
                            font.pixelSize: Properties.px(20)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Properties.px(154)
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackTitle || "Unknown Track") : ""
                            elide: Text.ElideRight
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSize
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
                            elide: Text.ElideRight
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }
                    }

                    Row {
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
                                color: mediaMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: Properties.colors.text
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.px(15)
                                }

                                MouseArea {
                                    id: mediaMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!root.player) return;
                                        if (modelData.action === "prev") root.player.previous();
                                        else if (modelData.action === "next") root.player.next();
                                        else root.player.togglePlaying();
                                        passInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
