# QuickShell Desktop Environment for Hyprland

A minimalist, self-contained desktop shell built with [QuickShell](https://quickshell.outfoxxed.me/) for **Hyprland**. It replaces standalone status bars, notification daemons, application launchers, OSDs, lock screens, Polkit agents, and idle managers with a single cohesive QML shell.

---

## ✨ Features

- **Minimalist Top Bar (`modules/Bar.qml`):**
  - Clock & interactive monthly calendar popup (`CalendarPopup.qml`).
  - Subtle active application logo indicator (`ActiveWindow.qml`) that smoothly fades out on empty workspaces.
  - Animated pill-based Hyprland workspace switcher (`Workspaces.qml`) with scroll-wheel navigation.
  - Live system indicators (`Weather`, `Brightness`, `Volume`, `Wi-Fi`, `Bluetooth`, `Battery`) with scroll-wheel adjustments, right-click quick toggles, and animated dropdown popups (`BarPopups.qml`).
- **Control Center Sidebar (`modules/Sidebar.qml`):**
  - User profile card with circular avatar, hostname, and email.
  - Quick actions (*App Launcher*, *Region Screenshot*, *System Settings*, *Power Menu*).
  - Quick toggles (*Wi-Fi*, *Bluetooth*, *Do Not Disturb*).
  - Interactive *Volume* and *Brightness* sliders with mouse wheel support.
  - MPRIS media player controller with album art.
  - Adaptive CPU, RAM, and CPU temperature monitor (polls rapidly only while the sidebar is open).
  - Notification history center with one-click app focusing.
- **Application Launcher (`modules/AppLauncher.qml`):**
  - Instant search, *Favorites* vs *All* tabs, custom favorite ordering (right-click context menu), and *List* / *Grid* view toggle.
- **System Settings (`modules/Settings.qml`):**
  - **Display:** Runtime UI scaling (`0.85x` – `1.25x`), per-monitor Hyprland scale, and brightness control.
  - **Theme:** 5 built-in color palettes (*VSCode Dark*, *Catppuccin Mocha*, *Tokyo Night*, *Nord*, *Gruvbox Dark*), 8 accent colors, **Hybrid (Sans + Mono)** vs **Full Monospace** typography toggle, and live `hyprpaper` wallpaper picker.
  - **Hyprland:** Live sliders for inner/outer gaps, corner rounding, border size, blur, and animations (persisted across sessions).
  - **Network, Bluetooth, Audio & Power:** Integrated device and profile management.
  - **Keybinds:** Live viewer and interactive keybind recorder for `~/.config/hypr/config/keybinds.lua`.
  - **Assistant & User:** Configurable CLI AI assistant launcher (`agy`, `claude`, `opencode`, `gemini`, `codex`) and user profile editor.
- **Window Switcher (`modules/AltTabMenu.qml`):**
  - Fast `Alt+Tab` / `Super+Tab` switcher with app icons, window titles, and automatic confirmation on modifier release.
- **On-Screen Display (`modules/Osd.qml`) & Notifications (`modules/Notifications.qml`):**
  - Bottom-center OSD for volume, microphone, brightness, and media keys.
  - Stacked bottom-right notification popups with hover-to-pause countdown bars and action buttons.
- **Native Daemons (`daemons/` & `modules/LockScreen.qml`):**
  - **LockScreen:** Wayland session lock (`WlSessionLock`) with blurred current wallpaper, PAM authentication, and MPRIS controls.
  - **PolkitDaemon:** Native Polkit authentication dialog.
  - **IdleDaemon:** 3-stage idle management (dim screen at 5m, lock session at 10m, DPMS off at 15m).
  - **AlertsDaemon:** Low/critical battery and high CPU temperature desktop alerts.

---

## 📦 Dependencies

### Required
- `quickshell` (built with Wayland, Hyprland, PAM, Polkit, PipeWire, UPower, Mpris, and SystemNotifications support)
- `hyprland`
- **Fonts:**
  - `JetBrainsMono Nerd Font` (`ttf-jetbrains-mono-nerd`) — used for icons, clock, metrics, and monospace mode.
  - `Inter` (`inter-font`) or `Adwaita Sans` — used for UI labels and prose in *Hybrid* typography mode.

### Optional Utilities
- `brightnessctl` — screen brightness control
- `nmcli` (NetworkManager) — connecting to new password-protected Wi-Fi networks
- `grim`, `slurp`, `wl-clipboard`, `libnotify` — region screenshots with clipboard copy and preview notification
- `hyprpaper` — wallpaper management
- `zenity` or `kdialog` — file picker dialogs for custom wallpapers and profile avatars

---

## 🚀 Installation

```bash
git clone <your-repo-url> ~/.config/quickshell
cp ~/.config/quickshell/config/user.example.json ~/.config/quickshell/config/user.json
```

Start QuickShell in your Hyprland configuration (`exec-once = qs` or `hl.exec_once("qs")`).

---

## ⌨️ IPC Commands (`qs ipc call ...`)

Bind these commands in your Hyprland config to control the shell via keyboard shortcuts:

| Target | Function | Command | Description |
| :--- | :--- | :--- | :--- |
| `launcher` | `toggle` | `qs ipc call launcher toggle` | Toggle the Application Launcher |
| `menu` | `toggle` | `qs ipc call menu toggle` | Toggle the General Quick Menu |
| `sidebar` | `toggle` | `qs ipc call sidebar toggle` | Toggle the Control Center Sidebar |
| `settings` | `toggle` | `qs ipc call settings toggle` | Toggle the System Settings window |
| `power` | `toggle` | `qs ipc call power toggle` | Toggle the Power Menu |
| `lock` | `lock` | `qs ipc call lock lock` | Lock the Wayland session immediately |
| `alttab` | `next` / `prev` / `confirm` | `qs ipc call alttab next` | Cycle and confirm the Alt-Tab window switcher |
| `osd` | `volume` / `brightness` / `mic` / `media <action>` | `qs ipc call osd brightness` | Trigger the bottom-center OSD |

---

## 📁 Directory Structure

```text
~/.config/quickshell/
├── shell.qml                 # Root entry point & modal coordinator
├── config/
│   ├── Properties.qml        # Design tokens, themes, scaling & persistent settings
│   ├── Favorites.qml         # Persistent favorite apps manager
│   ├── favorites.json        # Default favorite desktop entry IDs
│   └── user.example.json     # Template for local user profile overrides
├── services/
│   ├── SystemService.qml     # User info, adaptive CPU/RAM/Temp stats, screenshots & wallpapers
│   ├── NotificationService.qml # Notification server, popup queue & history
│   ├── BrightnessService.qml # Backlight controller via brightnessctl
│   └── WeatherService.qml    # Weather forecast service (wttr.in)
├── daemons/
│   ├── PolkitDaemon.qml      # Native Polkit authentication agent
│   ├── IdleDaemon.qml        # Auto-dim, auto-lock, and DPMS idle monitors
│   └── AlertsDaemon.qml      # Low battery & high temperature alerts
├── components/
│   ├── BarPill.qml           # Base interactive top-bar indicator pill
│   ├── ActiveWindow.qml      # Subtle active application icon indicator
│   ├── SliderControl.qml     # Interactive slider with thumb & wheel support
│   ├── popups/               # Dropdown popups for bar indicators
│   └── settings/             # Tabs for the System Settings window
└── modules/
    ├── Bar.qml               # Top status bar
    ├── BarPopups.qml         # Animated popup container for top bar items
    ├── Sidebar.qml           # Right control center & notification panel
    ├── AppLauncher.qml       # Application launcher with list/grid views
    ├── Settings.qml          # System settings modal
    ├── AltTabMenu.qml        # Window switcher overlay
    ├── GeneralMenu.qml       # Quick system menu
    ├── PowerMenu.qml         # Session power actions overlay
    ├── Notifications.qml     # Stacked notification toast popups
    ├── Osd.qml               # Volume/Brightness/Mic/Media OSD
    └── LockScreen.qml        # Blurred session lock screen
```
