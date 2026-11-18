import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Default CLI AI Assistant selector (launched from GeneralMenu -> Assistant)
Column {
    id: root

    property bool savedFeedback: false

    readonly property var presets: [
        { cmd: "agy",      title: "Antigravity CLI (agy)" },
        { cmd: "claude",   title: "Claude Code (claude)" },
        { cmd: "opencode", title: "OpenCode (opencode)" },
        { cmd: "gemini",   title: "Gemini CLI (gemini)" },
        { cmd: "codex",    title: "Codex CLI (codex)" }
    ]

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap * 1.5

    // Preset CLI assistants
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Default CLI Assistant"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: root.presets

            OptionItem {
                required property var modelData
                readonly property bool isActive: SystemService.defaultAssistant === modelData.cmd

                width: parent.width
                height: Properties.px(38)
                icon: isActive ? "󰄬" : "󰚩"
                title: modelData.title
                selected: isActive
                onTriggered: {
                    SystemService.setAssistant(modelData.cmd);
                    customInput.text = modelData.cmd;
                }
            }
        }
    }

    // Custom command
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap * 2

        Text {
            text: "Custom Command (runs in kitty)"
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
            border.color: customInput.activeFocus ? Properties.colors.accent : Properties.colors.border

            TextInput {
                id: customInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: SystemService.defaultAssistant
                color: Properties.colors.text
                font.family: Properties.typography.monoFamily
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
                text: root.savedFeedback ? "Saved!" : "Save Command"
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
                    SystemService.setAssistant(customInput.text);
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
