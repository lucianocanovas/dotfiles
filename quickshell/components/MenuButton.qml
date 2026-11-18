import QtQuick
import "../config"
import "../services"

// Main menu button in the top bar (toggles the right sidebar, shows DND indicator when active)
BarPill {
    id: root

    icon: root.active ? "󰅖" : (NotificationService.dnd ? "󰂛" : "☰")
    iconColor: NotificationService.dnd && !root.active ? Properties.colors.warning : Properties.colors.text
    onRightClicked: NotificationService.dnd = !NotificationService.dnd
}
