import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Editable user profile & avatar picker
Column {
    id: root

    property bool savedFeedback: false

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap * 1.5

    // Avatar + identity summary
    Rectangle {
        width: parent.width
        height: Properties.px(86)
        radius: Properties.radius.medium
        color: Properties.colors.moduleBackground

        Row {
            anchors.fill: parent
            anchors.margins: Properties.px(14)
            spacing: Properties.px(14)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Properties.px(58)
                height: Properties.px(58)
                radius: Properties.radius.pill
                color: Properties.colors.barBackground
                clip: true

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    visible: SystemService.avatarPath !== "" && status === Image.Ready
                    source: SystemService.avatarPath !== "" ? ("file://" + SystemService.avatarPath) : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !avatarImg.visible
                    text: "󰀄"
                    color: Properties.colors.accent
                    font.family: Properties.typography.iconFamily
                    font.pixelSize: Properties.px(28)
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Properties.px(180)
                spacing: 3

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
                    text: SystemService.username + "@" + SystemService.hostname
                    elide: Text.ElideRight
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Properties.px(100)
                height: Properties.px(32)
                radius: Properties.radius.medium
                color: avatarMouse.containsMouse ? Properties.colors.accent : Properties.colors.barBackground

                Text {
                    anchors.centerIn: parent
                    text: "Change Photo"
                    color: avatarMouse.containsMouse ? Properties.colors.textOnAccent : Properties.colors.text
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }

                MouseArea {
                    id: avatarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemService.pickAvatar()
                }
            }
        }
    }

    // Editable fields
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 2

        Text {
            text: "Full Name"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: Properties.px(38)
            radius: Properties.radius.medium
            color: Properties.colors.moduleBackground
            border.width: Properties.sizes.borderWidth
            border.color: nameInput.activeFocus ? Properties.colors.accent : Properties.colors.border

            TextInput {
                id: nameInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: SystemService.fullName
                color: Properties.colors.text
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
            }
        }

        Text {
            text: "Email"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: Properties.px(38)
            radius: Properties.radius.medium
            color: Properties.colors.moduleBackground
            border.width: Properties.sizes.borderWidth
            border.color: emailInput.activeFocus ? Properties.colors.accent : Properties.colors.border

            TextInput {
                id: emailInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: SystemService.email
                color: Properties.colors.text
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
            }
        }

        Rectangle {
            width: Properties.px(120)
            height: Properties.px(34)
            radius: Properties.radius.medium
            color: saveMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.accent

            Text {
                anchors.centerIn: parent
                text: root.savedFeedback ? "Saved!" : "Save Profile"
                color: Properties.colors.textOnAccent
                font.family: Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSizeSmall
                font.bold: true
            }

            MouseArea {
                id: saveMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SystemService.saveUserProfile(nameInput.text, emailInput.text);
                    root.savedFeedback = true;
                    feedbackTimer.restart();
                }
            }
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1500
        onTriggered: root.savedFeedback = false
    }
}
