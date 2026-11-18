import QtQuick
import Quickshell.Services.Pipewire
import "../config"

// Volume indicator connected to PipeWire (supports scroll wheel & right-click mute)
BarPill {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    PwObjectTracker {
        objects: [root.sink]
    }

    icon: {
        if (muted || percent === 0) return "󰖁";
        if (percent < 33) return "󰕿";
        if (percent < 66) return "󰖀";
        return "󰕾";
    }
    text: muted ? "" : (percent + "%")
    monospace: true
    contentColor: muted ? Properties.colors.textMuted : Properties.colors.text

    onRightClicked: {
        if (root.sink?.audio) {
            root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    onScrolled: step => {
        if (root.sink?.audio) {
            const next = Math.max(0, Math.min(100, root.percent + step * 5));
            if (step > 0 && root.sink.audio.muted) {
                root.sink.audio.muted = false;
            }
            root.sink.audio.volume = next / 100;
        }
    }
}
