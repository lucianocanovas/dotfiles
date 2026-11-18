import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
import "../../config"

// Reads, filters, and records Hyprland keybindings from ~/.config/hypr/config/keybinds.lua
Column {
    id: root

    property var parsedBinds: []
    property string filterText: ""
    property int recordingLineIndex: -1

    readonly property var filteredBinds: {
        const q = filterText.trim().toLowerCase();
        if (q === "") return parsedBinds;
        return parsedBinds.filter(b =>
            b.keys.toLowerCase().includes(q) || b.action.toLowerCase().includes(q)
        );
    }

    function parseKeybinds(content) {
        const result = [];
        const lines = content.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.startsWith("--")) continue;

            const match = line.match(/^(?:local\s+\w+\s*=\s*)?hl\.bind\(([^,]+),\s*(.+)\)$/);
            if (!match) continue;

            const rawKey = match[1].trim();
            const isLoopVar = /\.\.\s*i\b/.test(rawKey);

            let keys = rawKey
                .replace(/mainMod\s*\.\.\s*/g, "SUPER")
                .replace(/\.\.\s*i\b/g, "[1-5]")
                .replace(/["']/g, "")
                .replace(/\s*\.\.\s*/g, "")
                .trim();

            const isMouseOrRelease = keys.includes("mouse") || /\{\s*release\s*=\s*true\s*\}/.test(match[2]);
            const editable = !isLoopVar && !isMouseOrRelease;

            let action = match[2]
                .replace(/,\s*\{.*\}\s*$/, "")
                .replace(/^hl\.dsp\.exec_cmd\((.*)\)$/, "$1")
                .replace(/^["']|["']$/g, "")
                .trim();

            result.push({
                lineIndex: i,
                keys: keys,
                action: action,
                rawKeyExpr: rawKey,
                editable: editable
            });
        }
        root.parsedBinds = result;
    }

    function formatQtKeyCombo(event) {
        const mods = [];
        if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");
        if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
        if (event.modifiers & Qt.AltModifier) mods.push("ALT");
        if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");

        // Ignore lone modifier presses
        const ignored = [
            Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr,
            Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock
        ];
        if (ignored.includes(event.key)) return "";

        let keyName = "";
        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
            keyName = String.fromCharCode(event.key);
        } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            keyName = String.fromCharCode(event.key);
        } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
            keyName = "F" + (event.key - Qt.Key_F1 + 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyName = "Return";
        } else if (event.key === Qt.Key_Space) {
            keyName = "space";
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            keyName = "Tab";
        } else if (event.key === Qt.Key_Backspace) {
            keyName = "BackSpace";
        } else if (event.key === Qt.Key_Delete) {
            keyName = "Delete";
        } else if (event.key === Qt.Key_Home) {
            keyName = "Home";
        } else if (event.key === Qt.Key_End) {
            keyName = "End";
        } else if (event.key === Qt.Key_PageUp) {
            keyName = "Prior";
        } else if (event.key === Qt.Key_PageDown) {
            keyName = "Next";
        } else if (event.key === Qt.Key_Left) {
            keyName = "left";
        } else if (event.key === Qt.Key_Right) {
            keyName = "right";
        } else if (event.key === Qt.Key_Up) {
            keyName = "up";
        } else if (event.key === Qt.Key_Down) {
            keyName = "down";
        } else if (event.key === Qt.Key_Print) {
            keyName = "Print";
        } else if (event.key === Qt.Key_Minus) {
            keyName = "minus";
        } else if (event.key === Qt.Key_Equal) {
            keyName = "equal";
        } else if (event.key === Qt.Key_BracketLeft) {
            keyName = "bracketleft";
        } else if (event.key === Qt.Key_BracketRight) {
            keyName = "bracketright";
        } else if (event.key === Qt.Key_Backslash) {
            keyName = "backslash";
        } else if (event.key === Qt.Key_Semicolon) {
            keyName = "semicolon";
        } else if (event.key === Qt.Key_Apostrophe) {
            keyName = "apostrophe";
        } else if (event.key === Qt.Key_Comma) {
            keyName = "comma";
        } else if (event.key === Qt.Key_Period) {
            keyName = "period";
        } else if (event.key === Qt.Key_Slash) {
            keyName = "slash";
        } else if (event.key === Qt.Key_QuoteLeft) {
            keyName = "grave";
        } else {
            return "";
        }

        mods.push(keyName);
        return mods.join(" + ");
    }

    function updateBindLine(lineIdx, newCombo) {
        const lines = bindsFile.text().split("\n");
        if (lineIdx < 0 || lineIdx >= lines.length) return;
        lines[lineIdx] = lines[lineIdx].replace(
            /^(\s*(?:local\s+\w+\s*=\s*)?hl\.bind\()[^,]+,/,
            "$1\"" + newCombo + "\","
        );
        bindsFile.setText(lines.join("\n"));
        recordingLineIndex = -1;
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    FileView {
        id: bindsFile
        path: Quickshell.env("HOME") + "/.config/hypr/config/keybinds.lua"
        preload: true
        watchChanges: true
        onLoaded: root.parseKeybinds(bindsFile.text())
        onFileChanged: bindsFile.reload()
    }

    // Key recorder scope
    Item {
        id: recordScope
        focus: root.recordingLineIndex >= 0

        Keys.onPressed: event => {
            if (root.recordingLineIndex < 0) return;
            if (event.key === Qt.Key_Escape) {
                root.recordingLineIndex = -1;
                event.accepted = true;
                return;
            }
            const combo = root.formatQtKeyCombo(event);
            if (combo !== "") {
                root.updateBindLine(root.recordingLineIndex, combo);
                event.accepted = true;
            }
        }
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    spacing: Properties.spacing.overlayGap

    SearchInput {
        width: parent.width
        enabled: root.recordingLineIndex < 0
        placeholder: root.recordingLineIndex >= 0
            ? "Press new key combination (Escape to cancel)..."
            : "Filter keybinds..."
        onTextChanged: root.filterText = text
    }

    ListView {
        width: parent.width
        height: parent.height - Properties.sizes.searchHeight - Properties.spacing.overlayGap
        clip: true
        spacing: Properties.spacing.listGap
        model: root.filteredBinds

        delegate: Rectangle {
            required property var modelData
            readonly property bool isRecording: root.recordingLineIndex === modelData.lineIndex

            width: parent ? parent.width : 0
            height: Properties.px(38)
            radius: Properties.radius.medium
            color: isRecording ? Properties.colors.moduleHover : Properties.colors.moduleBackground
            border.width: isRecording ? 1 : 0
            border.color: Properties.colors.accent

            Row {
                anchors.fill: parent
                anchors.leftMargin: Properties.px(12)
                anchors.rightMargin: Properties.px(8)
                spacing: Properties.px(10)

                Rectangle {
                    id: keyBadge
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: keyLabel.implicitWidth + Properties.px(14)
                    implicitHeight: Properties.px(24)
                    radius: Properties.radius.small
                    color: Properties.colors.barBackground

                    Text {
                        id: keyLabel
                        anchors.centerIn: parent
                        text: isRecording ? "Listening..." : modelData.keys
                        color: Properties.colors.accent
                        font.family: Properties.typography.monoFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                        font.bold: true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - keyBadge.width - (modelData.editable ? recBtn.width : 0) - Properties.px(32)
                    text: modelData.action
                    elide: Text.ElideRight
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSizeSmall
                }

                Rectangle {
                    id: recBtn
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.editable
                    width: Properties.px(56)
                    height: Properties.px(24)
                    radius: Properties.radius.small
                    color: recMouse.containsMouse ? Properties.colors.accent : Properties.colors.barBackground

                    Text {
                        anchors.centerIn: parent
                        text: isRecording ? "Cancel" : "Record"
                        color: recMouse.containsMouse ? Properties.colors.textOnAccent : Properties.colors.text
                        font.family: Properties.typography.fontFamily
                        font.pixelSize: Properties.typography.fontSizeSmall
                    }

                    MouseArea {
                        id: recMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isRecording) {
                                root.recordingLineIndex = -1;
                            } else {
                                root.recordingLineIndex = modelData.lineIndex;
                                recordScope.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
