import QtQuick
import Quickshell
import Quickshell.Widgets
import "../components"
import "../config"
import "../services"

// Minimalist bottom-right notification popups
PanelWindow {
    id: root

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: Properties.spacing.overlayGap
        right: Properties.spacing.barHorizontalMargin
    }

    visible: NotificationService.popups.length > 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Properties.sizes.notificationWidth
    implicitHeight: popupsCol.implicitHeight

    Column {
        id: popupsCol
        width: parent.width
        spacing: Properties.spacing.listGap * 2

        Repeater {
            model: NotificationService.popups

            Surface {
                id: card
                required property var modelData // { notif, totalMs, remainingMs, paused }
                property bool entered: false

                readonly property var notif: modelData.notif
                readonly property var customActions: notif.actions.filter(a => a.identifier !== "default")
                readonly property real progress: Math.max(0, Math.min(1, modelData.remainingMs / modelData.totalMs))

                width: popupsCol.width
                implicitHeight: contentRow.implicitHeight + Properties.sizes.notificationPadding * 2 + Properties.sizes.notificationProgressHeight
                border.color: Properties.colors.border
                clip: true
                opacity: entered ? 1.0 : 0.0

                transform: Translate {
                    x: card.entered ? 0 : Properties.px(28)
                    Behavior on x {
                        NumberAnimation { duration: Properties.animation.expressive; easing.type: Easing.OutCubic }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
                }

                Component.onCompleted: entered = true

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: NotificationService.setPopupPaused(card.notif, containsMouse || closeMouse.containsMouse)
                    onClicked: NotificationService.focusApp(card.notif)
                }

                Row {
                    id: contentRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Properties.sizes.notificationPadding
                    spacing: Properties.spacing.overlayGap

                    // App icon / notification image
                    Item {
                        width: Properties.sizes.notificationIconSize
                        height: Properties.sizes.notificationIconSize
                        anchors.top: parent.top

                        Image {
                            id: notifImg
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: (card.notif.image ?? "") !== ""
                            source: card.notif.image ?? ""
                        }

                        IconImage {
                            id: appIconImg
                            anchors.fill: parent
                            readonly property string resolvedSource: (!notifImg.visible && card.notif.appIcon)
                                ? Quickshell.iconPath(card.notif.appIcon, true)
                                : ""
                            visible: resolvedSource !== ""
                            source: resolvedSource
                            implicitSize: Properties.sizes.notificationIconSize
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !notifImg.visible && !appIconImg.visible
                            text: "󰂚"
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.iconFamily
                            font.pixelSize: Properties.px(20)
                        }
                    }

                    // Text content
                    Column {
                        width: parent.width - Properties.sizes.notificationIconSize - Properties.spacing.overlayGap
                        spacing: 3

                        Item {
                            width: parent.width
                            height: Math.max(summaryText.implicitHeight, closeBtn.height)

                            Text {
                                id: summaryText
                                anchors.left: parent.left
                                anchors.right: closeBtn.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: card.notif.summary || card.notif.appName || "Notification"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Properties.colors.text
                                font.family: Properties.typography.fontFamily
                                font.pixelSize: Properties.typography.fontSize
                                font.bold: true
                            }

                            Rectangle {
                                id: closeBtn
                                anchors.right: parent.right
                                anchors.top: parent.top
                                width: Properties.px(20)
                                height: Properties.px(20)
                                radius: Properties.radius.small
                                color: closeMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: Properties.colors.textMuted
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.typography.fontSize
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onContainsMouseChanged: NotificationService.setPopupPaused(card.notif, containsMouse || cardMouse.containsMouse)
                                    onClicked: NotificationService.closeNotification(card.notif)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: (card.notif.body ?? "").replace(/\n+/g, " ").trim()
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            color: Properties.colors.textMuted
                            font.family: Properties.typography.fontFamily
                            font.pixelSize: Properties.typography.fontSizeSmall
                        }

                        Row {
                            visible: card.customActions.length > 0
                            spacing: 6
                            topPadding: 4

                            Repeater {
                                model: card.customActions

                                Rectangle {
                                    required property var modelData
                                    implicitWidth: actionLabel.implicitWidth + 14
                                    implicitHeight: Properties.px(22)
                                    radius: Properties.radius.small
                                    color: actionMouse.containsMouse ? Properties.colors.accent : Properties.colors.moduleBackground

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: actionMouse.containsMouse ? Properties.colors.textOnAccent : Properties.colors.text
                                        font.family: Properties.typography.fontFamily
                                        font.pixelSize: Properties.typography.fontSizeSmall
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelData.invoke();
                                            NotificationService.dismissPopup(card.notif);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Countdown progress bar driven by NotificationService remainingMs
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    height: Properties.sizes.notificationProgressHeight
                    width: Math.round(card.width * card.progress)
                    color: Properties.colors.accent
                }
            }
        }
    }
}
