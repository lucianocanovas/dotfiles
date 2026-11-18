import QtQuick
import "../config"

// Reusable search input field (used by AppLauncher, Settings, etc.)
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search..."

    signal accepted()
    signal escapePressed()
    signal moveUp()
    signal moveDown()
    signal moveLeft()
    signal moveRight()
    signal tabPressed()

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    implicitHeight: Properties.sizes.searchHeight
    radius: Properties.radius.medium
    color: Properties.colors.moduleBackground
    border.color: input.activeFocus ? Properties.colors.accent : Properties.colors.border
    border.width: Properties.sizes.borderWidth

    Behavior on border.color {
        ColorAnimation { duration: Properties.animation.fast }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Properties.px(10)
        anchors.rightMargin: Properties.px(10)
        spacing: Properties.px(8)

        // Search icon (Nerd Font)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: input.activeFocus ? Properties.colors.accent : Properties.colors.textMuted
            font.family: Properties.typography.iconFamily
            font.pixelSize: Properties.typography.iconSize

            Behavior on color {
                ColorAnimation { duration: Properties.animation.fast }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Properties.px(28) - (clearBtn.visible ? clearBtn.width + Properties.px(8) : 0)
            height: parent.height

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Properties.colors.text
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
                clip: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.escapePressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accepted();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.moveUp();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        root.moveDown();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left && input.text.length === 0) {
                        root.moveLeft();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right && input.text.length === 0) {
                        root.moveRight();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        root.tabPressed();
                        event.accepted = true;
                    }
                }
            }

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: root.placeholder
                color: Properties.colors.textMuted
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
                visible: input.text.length === 0
            }
        }

        Rectangle {
            id: clearBtn
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length > 0
            width: Properties.px(20)
            height: Properties.px(20)
            radius: Properties.radius.small
            color: clearMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Properties.colors.textMuted
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(12)
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.clear();
                    root.focusInput();
                }
            }
        }
    }
}
