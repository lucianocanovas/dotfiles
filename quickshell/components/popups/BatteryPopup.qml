import QtQuick
import Quickshell.Services.UPower
import "../../components"
import "../../config"

// Battery status, time remaining, power draw, and Power Profile selector
Column {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property int percent: Math.round((bat?.percentage ?? 0) * 100)
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
                                  || bat?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: bat?.state === UPowerDeviceState.FullyCharged
    readonly property real changeRate: Math.abs(bat?.changeRate ?? 0)
    readonly property int remainingSec: charging ? (bat?.timeToFull ?? 0) : (bat?.timeToEmpty ?? 0)

    function formatDuration(sec) {
        if (!sec || sec <= 60) return "";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    readonly property string statusText: {
        let base = "Discharging";
        if (full) base = "Fully Charged";
        else if (charging) base = "Charging";

        const parts = [base];
        const dur = formatDuration(remainingSec);
        if (dur !== "") parts.push(dur + (charging ? " to full" : " left"));
        if (changeRate > 0.1) parts.push(changeRate.toFixed(1) + " W");
        return parts.join(" • ");
    }

    readonly property var profiles: {
        const list = [
            { id: PowerProfile.PowerSaver, icon: "󰌪", title: "Power Saver" },
            { id: PowerProfile.Balanced,   icon: "󰾅", title: "Balanced" }
        ];
        if (PowerProfiles.hasPerformanceProfile) {
            list.push({ id: PowerProfile.Performance, icon: "󰓅", title: "Performance" });
        }
        return list;
    }

    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Battery summary
    Rectangle {
        width: parent.width
        height: Properties.px(54)
        radius: Properties.radius.medium
        color: Properties.colors.moduleBackground

        Row {
            anchors.fill: parent
            anchors.margins: Properties.px(12)
            spacing: Properties.px(12)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.charging ? "󰂄" : "󰁹"
                color: root.charging ? Properties.colors.success : Properties.colors.accent
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(22)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Properties.px(1)

                Text {
                    text: root.percent + "%"
                    color: Properties.colors.text
                    font.family: Properties.typography.monoFamily
                    font.pixelSize: Properties.typography.fontSizeLarge
                    font.bold: true
                }

                Text {
                    text: root.statusText
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }
            }
        }
    }

    // Power Profiles
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Power Mode"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: root.profiles

            OptionItem {
                required property var modelData
                readonly property bool isActive: PowerProfiles.profile === modelData.id

                width: parent.width
                height: Properties.px(38)
                icon: modelData.icon
                title: modelData.title
                selected: isActive
                onTriggered: PowerProfiles.profile = modelData.id
            }
        }
    }
}
