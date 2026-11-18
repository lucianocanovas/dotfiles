import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../components"
import "../config"
import "../services"

// Bottom-center OSD for volume, brightness, mic, and media controls
PanelWindow {
    id: root

    property bool isOpen: false
    property string mode: "volume" // "volume" | "brightness" | "mic" | "media"
    property string mediaAction: "toggle" // "play" | "pause" | "toggle" | "next" | "prev"
    property bool suppressInitialVolume: true

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    readonly property bool isVolumeMuted: sink?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool isMicMuted: source?.audio?.muted ?? false

    readonly property bool showBar: mode === "volume" || mode === "brightness"

    readonly property int barPercent: {
        if (mode === "brightness") return BrightnessService.percent;
        if (mode === "volume") return isVolumeMuted ? 0 : Math.min(100, volumePercent);
        return 0;
    }

    readonly property string osdIcon: {
        if (mode === "brightness") return BrightnessService.icon;
        if (mode === "volume") {
            if (isVolumeMuted || volumePercent === 0) return "󰖁";
            if (volumePercent < 33) return "󰕿";
            if (volumePercent < 66) return "󰖀";
            return "󰕾";
        }
        if (mode === "mic") return isMicMuted ? "󰍭" : "󰍬";
        if (mode === "media") {
            if (mediaAction === "next") return "󰒭";
            if (mediaAction === "prev") return "󰒮";
            if (mediaAction === "pause") return "󰏤";
            if (mediaAction === "play") return "󰐊";
            return (player?.isPlaying ?? false) ? "󰐊" : "󰏤";
        }
        return "󰕾";
    }

    readonly property string osdText: {
        if (mode === "brightness") return BrightnessService.percent + "%";
        if (mode === "volume") return isVolumeMuted ? "Muted" : (volumePercent + "%");
        if (mode === "mic") return isMicMuted ? "Mic Muted" : "Mic Active";
        if (mode === "media") {
            let label = "Media";
            if (mediaAction === "next") label = "Next";
            else if (mediaAction === "prev") label = "Previous";
            else if (mediaAction === "pause") label = "Paused";
            else if (mediaAction === "play") label = "Playing";
            else label = (player?.isPlaying ?? false) ? "Playing" : "Paused";

            const title = player?.trackTitle ?? "";
            return title !== "" ? (label + " • " + title) : label;
        }
        return "";
    }

    function show(newMode) {
        mode = newMode;
        isOpen = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Ignore initial PipeWire connection events at startup
    Timer {
        interval: 800
        running: true
        onTriggered: root.suppressInitialVolume = false
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            if (!root.suppressInitialVolume) root.show("volume");
        }
        function onMutedChanged() {
            if (!root.suppressInitialVolume) root.show("volume");
        }
    }

    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            if (!root.suppressInitialVolume) root.show("mic");
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.isOpen = false
    }

    IpcHandler {
        target: "osd"
        function brightness() {
            BrightnessService.refresh();
            root.show("brightness");
        }
        function volume() {
            root.show("volume");
        }
        function mic() {
            root.show("mic");
        }
        function media(action: string) {
            root.mediaAction = action || "toggle";
            root.show("media");
        }
    }

    anchors {
        bottom: true
    }

    margins {
        bottom: Properties.px(60)
    }

    visible: isOpen || osdCard.opacity > 0
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Properties.sizes.osdWidth
    implicitHeight: Properties.sizes.osdHeight

    Surface {
        id: osdCard
        anchors.fill: parent
        opacity: root.isOpen ? 1 : 0

        transform: Translate {
            y: root.isOpen ? 0 : Properties.px(16)
            Behavior on y {
                NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: Properties.sizes.overlayPadding
            anchors.rightMargin: Properties.sizes.overlayPadding
            spacing: Properties.spacing.overlayGap

            // Icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.osdIcon
                color: (root.mode === "volume" && root.isVolumeMuted) || (root.mode === "mic" && root.isMicMuted)
                    ? Properties.colors.textMuted
                    : Properties.colors.text
                font.family: Properties.typography.iconFamily
                font.pixelSize: Properties.px(20)
                width: Properties.px(24)
                horizontalAlignment: Text.AlignHCenter
            }

            // Progress bar (for volume & brightness)
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showBar
                width: parent.width - Properties.px(24) - valueText.width - Properties.spacing.overlayGap * 2
                height: Properties.sizes.osdBarHeight
                radius: Properties.radius.pill
                color: Properties.colors.moduleBackground

                Rectangle {
                    height: parent.height
                    width: Math.round(parent.width * (root.barPercent / 100))
                    radius: Properties.radius.pill
                    color: (root.mode === "volume" && root.isVolumeMuted)
                        ? Properties.colors.textMuted
                        : Properties.colors.accent

                    Behavior on width {
                        NumberAnimation { duration: Properties.animation.fast }
                    }
                }
            }

            // Value or media/mic label
            Text {
                id: valueText
                anchors.verticalCenter: parent.verticalCenter
                width: root.showBar ? Properties.px(48) : (parent.width - Properties.px(24) - Properties.spacing.overlayGap)
                horizontalAlignment: root.showBar ? Text.AlignRight : Text.AlignLeft
                text: root.osdText
                elide: Text.ElideRight
                color: Properties.colors.text
                font.family: root.showBar ? Properties.typography.monoFamily : Properties.typography.fontFamily
                font.pixelSize: Properties.typography.fontSize
                font.bold: true
            }
        }
    }
}
