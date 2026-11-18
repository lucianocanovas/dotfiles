import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../components"
import "../../config"
import "../../services"

// Power profiles & system power actions
Column {
    id: root

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

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap * 1.5

    // Power Profile
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Power Profile"
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

    // Power Actions
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Session & Power"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: SystemService.powerOptions

            OptionItem {
                required property var modelData
                width: parent.width
                height: Properties.px(38)
                icon: modelData.icon
                title: modelData.title
                onTriggered: SystemService.executePowerAction(modelData.id)
            }
        }
    }
}
