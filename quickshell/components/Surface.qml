import QtQuick
import "../config"

// Base styled container for menus, launchers, and floating overlays
Rectangle {
    color: Properties.colors.barBackground
    border.color: Properties.colors.border
    border.width: Properties.sizes.borderWidth
    radius: Properties.radius.large
}
