import QtQuick
import "../../config"
import "../../services"

// Weather summary popup for Weather widget
Column {
    id: root

    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Header: City + Refresh
    Item {
        width: parent.width
        height: Properties.px(24)

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.city !== "" ? WeatherService.city : "Local Weather"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Properties.px(24)
            height: Properties.px(24)
            radius: Properties.radius.small
            color: refreshMouse.containsMouse ? Properties.colors.moduleHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                color: Properties.colors.textMuted
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(14)
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WeatherService.refresh()
            }
        }
    }

    // Main condition card
    Rectangle {
        width: parent.width
        height: Properties.px(72)
        radius: Properties.radius.medium
        color: Properties.colors.moduleBackground

        Row {
            anchors.fill: parent
            anchors.margins: Properties.px(12)
            spacing: Properties.px(14)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherService.icon
                color: Properties.colors.accent
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(34)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: WeatherService.ready ? (WeatherService.temp + "°C") : "--°C"
                    color: Properties.colors.text
                    font.family: Properties.typography.monoFamily
                    font.pixelSize: Properties.px(20)
                    font.bold: true
                }

                Text {
                    text: WeatherService.condition !== "" ? WeatherService.condition : "Fetching forecast..."
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }
            }
        }
    }

    // Details row: Feels like, Humidity, Wind
    Row {
        width: parent.width
        spacing: Properties.spacing.listGap * 2

        Repeater {
            model: [
                { icon: "", label: "Feels",    value: WeatherService.feelsLike + "°C" },
                { icon: "󰖎", label: "Humidity", value: WeatherService.humidity + "%" },
                { icon: "󰖝", label: "Wind",     value: WeatherService.windKmph + " km/h" }
            ]

            Rectangle {
                required property var modelData
                width: (root.width - Properties.spacing.listGap * 4) / 3
                height: Properties.px(48)
                radius: Properties.radius.medium
                color: Properties.colors.moduleBackground

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon + " " + modelData.value
                        color: Properties.colors.text
                        font.family: Properties.typography.monoFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Properties.colors.textMuted
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                    }
                }
            }
        }
    }
}
