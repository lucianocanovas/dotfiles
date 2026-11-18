pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Global UI scale factor (1.0 = 100%, adjustable at runtime from Settings)
    property real scale: 1.0
    property string fontMode: "hybrid" // "hybrid" (Sans UI + Mono data) | "mono" (Full JetBrains Mono)
    property string themeName: "VSCode Dark"
    property bool dnd: false
    property var monitorScales: ({})
    property var hyprlandOverrides: null
    property bool settingsLoaded: false

    readonly property string settingsFilePath: Qt.resolvedUrl("settings.json").toString().replace(/^file:\/\//, "")

    readonly property var themePresets: [
        {
            name: "VSCode Dark",
            barBackground: "#1E1E1E", moduleBackground: "#2D2D2D", moduleHover: "#3A3A3A",
            border: "#3E3E42", accent: "#007ACC", text: "#FFFFFF", textMuted: "#A0A0A0", textOnAccent: "#FFFFFF"
        },
        {
            name: "Catppuccin Mocha",
            barBackground: "#1E1E2E", moduleBackground: "#313244", moduleHover: "#45475A",
            border: "#45475A", accent: "#89B4FA", text: "#CDD6F4", textMuted: "#A6ADC8", textOnAccent: "#1E1E2E"
        },
        {
            name: "Tokyo Night",
            barBackground: "#1A1B26", moduleBackground: "#24283B", moduleHover: "#2F3549",
            border: "#3B4261", accent: "#7AA2F7", text: "#C0CAF5", textMuted: "#787C99", textOnAccent: "#1A1B26"
        },
        {
            name: "Nord",
            barBackground: "#2E3440", moduleBackground: "#3B4252", moduleHover: "#434C5E",
            border: "#4C566A", accent: "#88C0D0", text: "#ECEFF4", textMuted: "#D8DEE9", textOnAccent: "#2E3440"
        },
        {
            name: "Gruvbox Dark",
            barBackground: "#282828", moduleBackground: "#3C3836", moduleHover: "#504945",
            border: "#504945", accent: "#FABD2F", text: "#EBDBB2", textMuted: "#A89984", textOnAccent: "#282828"
        }
    ]

    readonly property var accentPresets: [
        "#007ACC", "#89B4FA", "#A6E3A1", "#F38BA8", "#CBA6F7", "#FAB387", "#88C0D0", "#FABD2F"
    ]

    function px(value) {
        return Math.round(value * scale);
    }

    function setScale(newScale) {
        scale = newScale;
        saveSettings();
    }

    function setFontMode(mode) {
        fontMode = mode === "mono" ? "mono" : "hybrid";
        saveSettings();
    }

    function setDnd(enabled) {
        dnd = Boolean(enabled);
        saveSettings();
    }

    function applyTheme(theme) {
        if (theme.name) themeName = theme.name;
        colors.barBackground = theme.barBackground;
        colors.moduleBackground = theme.moduleBackground;
        colors.moduleHover = theme.moduleHover;
        colors.border = theme.border;
        colors.accent = theme.accent;
        colors.text = theme.text;
        colors.textMuted = theme.textMuted;
        colors.textOnAccent = theme.textOnAccent;
        saveSettings();
    }

    function setAccent(accentHex) {
        colors.accent = accentHex;
        // Calculate perceived luminance so textOnAccent stays legible
        const hex = String(accentHex).replace("#", "");
        if (hex.length === 6) {
            const r = parseInt(hex.substring(0, 2), 16);
            const g = parseInt(hex.substring(2, 4), 16);
            const b = parseInt(hex.substring(4, 6), 16);
            const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
            colors.textOnAccent = lum > 0.62 ? "#1E1E2E" : "#FFFFFF";
        }
        saveSettings();
    }

    function saveHyprlandOption(key, value) {
        const current = hyprlandOverrides ? Object.assign({}, hyprlandOverrides) : {};
        current[key] = value;
        hyprlandOverrides = current;
        Quickshell.execDetached(["hyprctl", "keyword", key, String(value)]);
        saveSettings();
    }

    function saveMonitorScale(monName, scaleVal) {
        const current = monitorScales ? Object.assign({}, monitorScales) : {};
        current[monName] = scaleVal;
        monitorScales = current;
        Quickshell.execDetached([
            "hyprctl", "keyword", "monitor",
            monName + ",preferred,auto," + scaleVal
        ]);
        saveSettings();
    }

    function applyStoredHyprlandSettings() {
        const cmds = [];
        if (hyprlandOverrides && typeof hyprlandOverrides === "object") {
            const keys = Object.keys(hyprlandOverrides);
            for (let i = 0; i < keys.length; i++) {
                const k = keys[i];
                cmds.push("hyprctl keyword " + k + " " + String(hyprlandOverrides[k]));
            }
        }
        if (monitorScales && typeof monitorScales === "object") {
            const mons = Object.keys(monitorScales);
            for (let i = 0; i < mons.length; i++) {
                const m = mons[i];
                cmds.push("hyprctl keyword monitor " + m + ",preferred,auto," + monitorScales[m]);
            }
        }
        if (cmds.length > 0) {
            Quickshell.execDetached(["sh", "-c", cmds.join(" >/dev/null 2>&1; ") + " >/dev/null 2>&1"]);
        }
    }

    function loadSettingsFromText(raw) {
        try {
            const data = JSON.parse(raw);
            if (typeof data.scale === "number" && data.scale >= 0.5 && data.scale <= 2.5) {
                root.scale = data.scale;
            }
            if (data.fontMode === "mono" || data.fontMode === "hybrid") {
                root.fontMode = data.fontMode;
            }
            if (typeof data.themeName === "string") {
                root.themeName = data.themeName;
            }
            if (typeof data.dnd === "boolean") {
                root.dnd = data.dnd;
            }
            if (data.colors && typeof data.colors === "object") {
                if (data.colors.barBackground) colors.barBackground = data.colors.barBackground;
                if (data.colors.moduleBackground) colors.moduleBackground = data.colors.moduleBackground;
                if (data.colors.moduleHover) colors.moduleHover = data.colors.moduleHover;
                if (data.colors.border) colors.border = data.colors.border;
                if (data.colors.accent) colors.accent = data.colors.accent;
                if (data.colors.text) colors.text = data.colors.text;
                if (data.colors.textMuted) colors.textMuted = data.colors.textMuted;
                if (data.colors.textOnAccent) colors.textOnAccent = data.colors.textOnAccent;
            }
            if (data.hyprland && typeof data.hyprland === "object") {
                root.hyprlandOverrides = data.hyprland;
            }
            if (data.monitorScales && typeof data.monitorScales === "object") {
                root.monitorScales = data.monitorScales;
            }
        } catch (e) {
            // Keep defaults if settings.json is missing or invalid
        }
        if (!root.settingsLoaded) {
            root.settingsLoaded = true;
            root.applyStoredHyprlandSettings();
        }
    }

    function saveSettings() {
        if (!root.settingsLoaded) return;
        const payload = {
            scale: root.scale,
            fontMode: root.fontMode,
            themeName: root.themeName,
            colors: {
                barBackground: colors.barBackground.toString(),
                moduleBackground: colors.moduleBackground.toString(),
                moduleHover: colors.moduleHover.toString(),
                border: colors.border.toString(),
                accent: colors.accent.toString(),
                text: colors.text.toString(),
                textMuted: colors.textMuted.toString(),
                textOnAccent: colors.textOnAccent.toString()
            },
            dnd: root.dnd,
            hyprland: root.hyprlandOverrides,
            monitorScales: root.monitorScales
        };
        settingsFile.setText(JSON.stringify(payload, null, 4) + "\n");
    }

    FileView {
        id: settingsFile
        path: root.settingsFilePath
        preload: true
        onLoaded: root.loadSettingsFromText(settingsFile.text())
    }

    // COLOR
    readonly property QtObject colors: QtObject {
        property color barBackground: "#1E1E1E"
        property color moduleBackground: "#2D2D2D"
        property color moduleHover: "#3A3A3A"
        property color border: "#3E3E42"

        property color accent: "#007ACC"
        property color text: "#FFFFFF"
        property color textMuted: "#A0A0A0"
        property color textOnAccent: "#FFFFFF"

        readonly property color success: "#4EC9B0"
        readonly property color warning: "#CE9178"
        readonly property color error: "#F44747"
    }

    // SIZE (all scaled by root.scale)
    readonly property QtObject sizes: QtObject {
        readonly property int barHeight: root.px(40)
        readonly property int moduleHeight: root.px(28)
        readonly property int modulePadding: root.px(16)
        readonly property int borderWidth: Math.max(1, root.px(1))

        // Workspaces
        readonly property int workspaceSize: root.px(30)
        readonly property int workspaceDotHeight: root.px(8)
        readonly property int workspaceDotWidth: root.px(8)
        readonly property int workspaceDotActiveWidth: root.px(18)

        // Menus & overlays
        readonly property int menuWidth: root.px(320)
        readonly property int launcherWidth: root.px(420)
        readonly property int launcherHeight: root.px(480)
        readonly property int overlayPadding: root.px(16)
        readonly property int optionHeight: root.px(46)
        readonly property int listIconSize: root.px(26)
        readonly property int gridCellHeight: root.px(96)
        readonly property int gridIconSize: root.px(38)
        readonly property int searchHeight: root.px(38)
        readonly property int tabHeight: root.px(28)
        readonly property int contextMenuWidth: root.px(210)
        readonly property int contextMenuItemHeight: root.px(34)
        readonly property int altTabTileSize: root.px(56)
        readonly property int altTabIconSize: root.px(34)

        // Notifications
        readonly property int notificationWidth: root.px(360)
        readonly property int notificationPadding: root.px(14)
        readonly property int notificationIconSize: root.px(32)
        readonly property int notificationProgressHeight: Math.max(2, root.px(3))

        // OSD
        readonly property int osdWidth: root.px(280)
        readonly property int osdHeight: root.px(52)
        readonly property int osdBarHeight: root.px(6)

        // Sidebar
        readonly property int sidebarWidth: root.px(360)

        // Bar popups
        readonly property int popupWidth: root.px(320)
        readonly property int calendarPopupWidth: root.px(290)

        // Settings
        readonly property int settingsWidth: root.px(740)
        readonly property int settingsHeight: root.px(520)
        readonly property int settingsNavWidth: root.px(180)
    }

    // SPACING (all scaled by root.scale)
    readonly property QtObject spacing: QtObject {
        readonly property int barHorizontalMargin: root.px(20)
        readonly property int sectionSpacing: root.px(10)
        readonly property int moduleGap: root.px(6)
        readonly property int workspaceSpacing: root.px(5)
        readonly property int listGap: root.px(4)
        readonly property int overlayGap: root.px(12)
    }

    // RADIUS
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int small: root.px(4)
        readonly property int medium: root.px(6)
        readonly property int large: root.px(10)
        readonly property int pill: 999
        readonly property int module: medium
    }

    // TYPOGRAPHY
    readonly property QtObject typography: QtObject {
        readonly property string detectedSansFamily: {
            const families = Qt.fontFamilies();
            const candidates = ["Inter", "Adwaita Sans", "Roboto", "Noto Sans", "Liberation Sans"];
            for (let i = 0; i < candidates.length; i++) {
                if (families.includes(candidates[i])) return candidates[i];
            }
            return "JetBrainsMono Nerd Font";
        }
        readonly property string fontFamily: root.fontMode === "mono"
            ? "JetBrainsMono Nerd Font"
            : detectedSansFamily
        readonly property string monoFamily: "JetBrainsMono Nerd Font"
        readonly property string iconFamily: "JetBrainsMono Nerd Font"
        readonly property int fontSize: root.px(12)
        readonly property int fontSizeSmall: root.px(10)
        readonly property int fontSizeLarge: root.px(14)
        readonly property int iconSize: root.px(14)
    }

    // ANIMATION
    readonly property QtObject animation: QtObject {
        readonly property int fast: 120
        readonly property int normal: 200
        readonly property int expressive: 280
        readonly property int slow: 350
    }
}
