import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Brightness slider popup
Column {
    width: Properties.sizes.popupWidth - Properties.sizes.overlayPadding * 2
    spacing: Properties.spacing.listGap * 2

    Text {
        text: "Screen Brightness"
        color: Properties.colors.textMuted
        font.family: Properties.typography.fontFamily
        font.pixelSize: Properties.typography.fontSizeSmall
        font.bold: true
    }

    SliderControl {
        width: parent.width
        icon: BrightnessService.icon
        value: BrightnessService.percent
        onMoved: newVal => BrightnessService.set(newVal)
    }
}
