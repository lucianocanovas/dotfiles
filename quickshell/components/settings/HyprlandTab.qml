import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
import "../../config"

// Live Hyprland configuration controls (gaps, border, rounding, blur, animations)
Column {
    id: root

    property int gapsIn: 5
    property int gapsOut: 10
    property int borderSize: 2
    property int rounding: 10
    property bool blurEnabled: true
    property bool animationsEnabled: true

    function setKeyword(key, val) {
        Properties.saveHyprlandOption(key, val);
    }

    // Load current Hyprland runtime values on open
    Process {
        id: queryProc
        command: [
            "sh", "-c",
            "for opt in general:gaps_in general:gaps_out general:border_size decoration:rounding decoration:blur:enabled animations:enabled; do " +
            "  hyprctl getoption \"$opt\" -j 2>/dev/null | tr -d '\\n'; echo; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const parseIntOpt = (line, defVal) => {
                    try {
                        const obj = JSON.parse(line);
                        if (obj.int !== undefined) return obj.int;
                        if (obj.custom !== undefined) return parseInt(obj.custom.split(" ")[0]) || defVal;
                    } catch (e) {}
                    return defVal;
                };
                if (lines.length >= 6) {
                    root.gapsIn = parseIntOpt(lines[0], root.gapsIn);
                    root.gapsOut = parseIntOpt(lines[1], root.gapsOut);
                    root.borderSize = parseIntOpt(lines[2], root.borderSize);
                    root.rounding = parseIntOpt(lines[3], root.rounding);
                    root.blurEnabled = parseIntOpt(lines[4], 1) === 1;
                    root.animationsEnabled = parseIntOpt(lines[5], 1) === 1;
                }
            }
        }
        Component.onCompleted: running = true
    }

    width: parent ? parent.width : 0
    spacing: Properties.spacing.overlayGap

    Text {
        text: "Hyprland Appearance (Live)"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
        font.bold: true
    }

    // Gaps In
    SliderControl {
        width: parent.width
        icon: "󰩨"
        value: Math.round((root.gapsIn / 20) * 100)
        onMoved: pct => {
            root.gapsIn = Math.round((pct / 100) * 20);
            root.setKeyword("general:gaps_in", root.gapsIn);
        }
    }
    Text {
        text: "Inner Gaps: " + root.gapsIn + " px"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
    }

    // Gaps Out
    SliderControl {
        width: parent.width
        icon: "󰩬"
        value: Math.round((root.gapsOut / 30) * 100)
        onMoved: pct => {
            root.gapsOut = Math.round((pct / 100) * 30);
            root.setKeyword("general:gaps_out", root.gapsOut);
        }
    }
    Text {
        text: "Outer Gaps: " + root.gapsOut + " px"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
    }

    // Rounding
    SliderControl {
        width: parent.width
        icon: "󰗅"
        value: Math.round((root.rounding / 20) * 100)
        onMoved: pct => {
            root.rounding = Math.round((pct / 100) * 20);
            root.setKeyword("decoration:rounding", root.rounding);
        }
    }
    Text {
        text: "Corner Rounding: " + root.rounding + " px"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
    }

    // Border Size
    SliderControl {
        width: parent.width
        icon: "󰔉"
        value: Math.round((root.borderSize / 5) * 100)
        onMoved: pct => {
            root.borderSize = Math.round((pct / 100) * 5);
            root.setKeyword("general:border_size", root.borderSize);
        }
    }
    Text {
        text: "Border Size: " + root.borderSize + " px"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
    }

    // Toggles: Blur & Animations
    Row {
        width: parent.width
        spacing: Properties.spacing.listGap * 2

        Repeater {
            model: [
                { id: "blur", label: "Blur", active: root.blurEnabled },
                { id: "anim", label: "Animations", active: root.animationsEnabled }
            ]

            Rectangle {
                required property var modelData
                width: (parent.width - Properties.spacing.listGap * 2) / 2
                height: Properties.px(36)
                radius: Properties.radius.medium
                color: modelData.active ? Properties.colors.accent : Properties.colors.moduleBackground

                Text {
                    anchors.centerIn: parent
                    text: modelData.label + ": " + (modelData.active ? "On" : "Off")
                    color: modelData.active ? Properties.colors.textOnAccent : Properties.colors.text
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                    font.bold: modelData.active
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.id === "blur") {
                            root.blurEnabled = !root.blurEnabled;
                            root.setKeyword("decoration:blur:enabled", root.blurEnabled ? "true" : "false");
                        } else {
                            root.animationsEnabled = !root.animationsEnabled;
                            root.setKeyword("animations:enabled", root.animationsEnabled ? "true" : "false");
                        }
                    }
                }
            }
        }
    }
}
