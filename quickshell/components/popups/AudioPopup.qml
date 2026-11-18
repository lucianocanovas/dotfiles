import QtQuick
import Quickshell.Services.Pipewire
import "../../components"
import "../../config"

// Audio popup with output/microphone volume sliders and output/input device selector
Column {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool isMuted: sink?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool isMicMuted: source?.audio?.muted ?? false
    readonly property int micPercent: Math.round((source?.audio?.volume ?? 0) * 100)

    // Filter PipeWire nodes into physical output sinks and input sources (excluding app streams)
    readonly property var outputDevices: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var inputDevices: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.overlayGap

    // Output Volume Slider
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Output Volume"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        SliderControl {
            width: parent.width
            icon: root.isMuted || root.volumePercent === 0 ? "󰖁" : "󰕾"
            value: root.isMuted ? 0 : Math.min(100, root.volumePercent)
            muted: root.isMuted
            onMoved: newVal => {
                if (root.sink?.audio) {
                    root.sink.audio.muted = false;
                    root.sink.audio.volume = newVal / 100;
                }
            }
            onIconClicked: {
                if (root.sink?.audio) {
                    root.sink.audio.muted = !root.sink.audio.muted;
                }
            }
        }
    }

    // Microphone Volume Slider
    Column {
        width: parent.width
        visible: root.source !== null
        spacing: Properties.spacing.listGap

        Text {
            text: "Microphone"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        SliderControl {
            width: parent.width
            icon: root.isMicMuted || root.micPercent === 0 ? "󰍭" : "󰍬"
            value: root.isMicMuted ? 0 : Math.min(100, root.micPercent)
            muted: root.isMicMuted
            onMoved: newVal => {
                if (root.source?.audio) {
                    root.source.audio.muted = false;
                    root.source.audio.volume = newVal / 100;
                }
            }
            onIconClicked: {
                if (root.source?.audio) {
                    root.source.audio.muted = !root.source.audio.muted;
                }
            }
        }
    }

    // Output devices
    Column {
        width: parent.width
        spacing: Properties.spacing.listGap

        Text {
            text: "Output Device"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: root.outputDevices

            OptionItem {
                required property var modelData
                readonly property bool isActive: modelData === root.sink

                width: parent.width
                height: Properties.px(36)
                icon: isActive ? "󰄬" : "󰓃"
                title: modelData.description || modelData.nickname || "Output"
                selected: isActive
                onTriggered: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    // Input devices
    Column {
        width: parent.width
        visible: root.inputDevices.length > 0
        spacing: Properties.spacing.listGap

        Text {
            text: "Input Device"
            color: Properties.colors.textMuted
            font.family: Properties.typography.fontFamily
            font.pixelSize: Properties.typography.fontSizeSmall
            font.bold: true
        }

        Repeater {
            model: root.inputDevices

            OptionItem {
                required property var modelData
                readonly property bool isActive: modelData === root.source

                width: parent.width
                height: Properties.px(36)
                icon: isActive ? "󰄬" : "󰍬"
                title: modelData.description || modelData.nickname || "Input"
                selected: isActive
                onTriggered: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}
