import QtQuick
import "../../config"

// Calendar dropdown popup for Clock
Column {
    id: root

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() // 0-11

    readonly property var today: new Date()
    readonly property string monthLabel: Qt.locale("en_US").toString(new Date(viewYear, viewMonth, 1), "MMMM yyyy")

    // Build 42-day grid (Monday-first)
    readonly property var calendarDays: {
        const firstDay = new Date(viewYear, viewMonth, 1);
        const startOffset = (firstDay.getDay() + 6) % 7; // Convert Sun=0..Sat=6 to Mon=0..Sun=6
        const startDate = new Date(viewYear, viewMonth, 1 - startOffset);
        const days = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);
            days.push({
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth,
                isToday: d.getFullYear() === today.getFullYear()
                      && d.getMonth() === today.getMonth()
                      && d.getDate() === today.getDate()
            });
        }
        return days;
    }

    function stepMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    width: Properties.sizes.calendarPopupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Header: < Month Year >
    Item {
        width: parent.width
        height: Properties.px(28)

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Properties.px(28)
            height: Properties.px(28)
            radius: Properties.radius.small
            color: prevMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

            Text {
                anchors.centerIn: parent
                text: "󰅁"
                color: Properties.colors.text
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(16)
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stepMonth(-1)
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.monthLabel
            color: Properties.colors.text
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeLarge
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.viewYear = root.today.getFullYear();
                    root.viewMonth = root.today.getMonth();
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Properties.px(28)
            height: Properties.px(28)
            radius: Properties.radius.small
            color: nextMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

            Text {
                anchors.centerIn: parent
                text: "󰅂"
                color: Properties.colors.text
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(16)
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stepMonth(1)
            }
        }
    }

    // Weekday headers
    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Item {
                required property string modelData
                width: Math.floor(root.width / 7)
                height: Properties.px(24)

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: true
                }
            }
        }
    }

    // Day cells
    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: root.calendarDays

            Item {
                required property var modelData
                width: Math.floor(root.width / 7)
                height: Properties.px(32)

                Rectangle {
                    anchors.centerIn: parent
                    width: Properties.px(28)
                    height: Properties.px(28)
                    radius: Properties.radius.small
                    color: modelData.isToday ? Properties.colors.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: {
                            if (modelData.isToday) return Properties.colors.textOnAccent;
                            return modelData.inMonth ? Properties.colors.text : Properties.colors.textMuted;
                        }
                        opacity: modelData.inMonth || modelData.isToday ? 1.0 : 0.45
                        font.family: Properties.typography.monoFamily
                        font.pixelSize: Properties.typography.fontSize
                        font.bold: modelData.isToday
                    }
                }
            }
        }
    }
}
