import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import "../components"
import "../config"

// Polkit authentication agent daemon (replaces hyprpolkitagent / polkit-gnome)
Scope {
    id: root

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: {
            passInput.text = "";
            passInput.forceActiveFocus();
        }
    }

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        visible: agent.isActive
        focusable: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        // Dimmed backdrop
        Rectangle {
            anchors.fill: parent
            color: "#66000000"
        }

        Surface {
            anchors.centerIn: parent
            width: Properties.px(380)
            height: polkitCol.implicitHeight + Properties.sizes.overlayPadding * 2

            Column {
                id: polkitCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Properties.sizes.overlayPadding
                spacing: Properties.spacing.overlayGap

                Row {
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌾"
                        color: Properties.colors.accent
                        font.family: Properties.typography.iconFamily
                        font.pixelSize: Properties.px(20)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Authentication Required"
                        color: Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeLarge
                        font.bold: true
                    }
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: agent.flow?.message ?? ""
                    wrapMode: Text.WordWrap
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }

                Rectangle {
                    width: parent.width
                    height: Properties.sizes.searchHeight
                    radius: Properties.radius.medium
                    color: Properties.colors.moduleBackground
                    border.width: Properties.sizes.borderWidth
                    border.color: passInput.activeFocus ? Properties.colors.accent : Properties.colors.border

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: (agent.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                        color: Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSize

                        onAccepted: {
                            if (agent.flow) {
                                agent.flow.submit(text);
                                text = "";
                            }
                        }

                        Keys.onEscapePressed: {
                            if (agent.flow) agent.flow.cancelAuthenticationRequest();
                        }
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: agent.flow?.inputPrompt || "Password"
                        color: Properties.colors.textMuted
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSize
                        visible: passInput.text.length === 0
                    }
                }

                Text {
                    width: parent.width
                    visible: (agent.flow?.supplementaryMessage ?? "") !== ""
                    text: agent.flow?.supplementaryMessage ?? ""
                    wrapMode: Text.WordWrap
                    color: (agent.flow?.supplementaryIsError ?? false) ? Properties.colors.error : Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Rectangle {
                        width: Properties.px(84)
                        height: Properties.px(32)
                        radius: Properties.radius.medium
                        color: cancelMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Properties.colors.text
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (agent.flow) agent.flow.cancelAuthenticationRequest();
                            }
                        }
                    }

                    Rectangle {
                        width: Properties.px(108)
                        height: Properties.px(32)
                        radius: Properties.radius.medium
                        color: authMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Authenticate"
                            color: Properties.colors.textOnAccent
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                            font.bold: true
                        }

                        MouseArea {
                            id: authMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (agent.flow) {
                                    agent.flow.submit(passInput.text);
                                    passInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
