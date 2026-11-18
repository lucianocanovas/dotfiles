import QtQuick
import Quickshell

// Clock displaying month name, day number, and 24h time (e.g., "April 22 - 12:25")
BarPill {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    icon: "󰥔"
    text: Qt.locale("en_US").toString(clock.date, "MMM d • HH:mm")
    monospace: true
}
