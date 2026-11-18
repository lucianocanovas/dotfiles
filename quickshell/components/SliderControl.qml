import QtQuick
import "../config"

// Reusable horizontal slider control with icon, interactive thumb, mouse wheel, and percentage label
Rectangle {
    id: root

    property string icon: ""
    property int value: 0
    property bool muted: false

    signal moved(int newValue)
    signal iconClicked()

    readonly property real clampedRatio: Math.max(0, Math.min(100, root.value)) / 100

    implicitHeight: Properties.px(36)
    radius: Properties.radius.medium
    color: Properties.colors.moduleBackground

    Row {
        anchors.fill: parent
        anchors.leftMargin: Properties.px(12)
        anchors.rightMargin: Properties.px(12)
        spacing: Properties.spacing.overlayGap

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Properties.px(24)
            height: Properties.px(24)
            radius: Properties.radius.small
            color: iconMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.muted ? Properties.colors.textMuted : Properties.colors.text
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(16)
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Item {
            id: trackArea
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Properties.px(24) - pctText.width - Properties.spacing.overlayGap * 2
            height: Properties.px(24)

            Rectangle {
                id: trackBg
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: sliderMouse.containsMouse || sliderMouse.pressed
                    ? Properties.px(8)
                    : Properties.sizes.osdBarHeight
                radius: Properties.radius.pill
                color: Properties.colors.barBackground

                Behavior on height {
                    NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    id: fillBar
                    height: parent.height
                    width: Math.round(parent.width * root.clampedRatio)
                    radius: Properties.radius.pill
                    color: root.muted ? Properties.colors.textMuted : Properties.colors.accent

                    Behavior on width {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Properties.animation.fast }
                    }
                }
            }

            // Interactive thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Properties.px(14)
                height: Properties.px(14)
                radius: Properties.radius.pill
                x: Math.max(0, Math.min(parent.width - width, fillBar.width - width / 2))
                color: Properties.colors.text
                border.width: Properties.px(2)
                border.color: root.muted ? Properties.colors.textMuted : Properties.colors.accent
                scale: (sliderMouse.containsMouse || sliderMouse.pressed) ? 1.0 : 0.0
                opacity: (sliderMouse.containsMouse || sliderMouse.pressed) ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: sliderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateFromMouse(mouseX) {
                    const ratio = Math.max(0, Math.min(1, mouseX / width));
                    root.moved(Math.round(ratio * 100));
                }

                onPressed: mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) updateFromMouse(mouse.x);
                }
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    root.moved(Math.max(0, Math.min(100, root.value + delta)));
                }
            }
        }

        Text {
            id: pctText
            anchors.verticalCenter: parent.verticalCenter
            width: Properties.px(38)
            horizontalAlignment: Text.AlignRight
            text: root.value + "%"
            color: Properties.colors.textMuted
            font.family: Properties.typography.monoFamily
            font.pixelSize: Properties.typography.fontSizeSmall
        }
    }
}
