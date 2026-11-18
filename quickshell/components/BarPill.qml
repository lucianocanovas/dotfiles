import QtQuick
import "../config"

// Reusable interactive pill container for top bar indicators
Rectangle {
    id: root

    property bool active: false
    property string icon: ""
    property string text: ""
    property bool monospace: true
    property color contentColor: Properties.colors.text
    property color iconColor: contentColor

    signal clicked()
    signal rightClicked()
    signal scrolled(int step)

    implicitWidth: contentRow.implicitWidth + Properties.sizes.modulePadding
    implicitHeight: Properties.sizes.moduleHeight
    radius: Properties.radius.module
    color: {
        if (root.active) return Properties.colors.accent;
        if (mouse.containsMouse) return Properties.colors.moduleHover;
        return Properties.colors.moduleBackground;
    }

    Behavior on color {
        ColorAnimation { duration: Properties.animation.fast }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Properties.animation.fast; easing.type: Easing.OutCubic }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Properties.px(6)

        Text {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active ? Properties.colors.textOnAccent : root.iconColor
            font.family: Properties.typography.iconFamily
            font.pixelSize: Properties.typography.iconSize

            Behavior on color {
                ColorAnimation { duration: Properties.animation.fast }
            }
        }

        Text {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.active ? Properties.colors.textOnAccent : root.contentColor
            font.family: root.monospace ? Properties.typography.monoFamily : Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSize

            Behavior on color {
                ColorAnimation { duration: Properties.animation.fast }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton || event.button === Qt.MiddleButton) {
                root.rightClicked();
            } else {
                root.clicked();
            }
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.scrolled(1);
            else if (wheel.angleDelta.y < 0) root.scrolled(-1);
        }
    }
}
