import QtQuick
import "../services"

// Weather indicator (reads from WeatherService)
BarPill {
    icon: WeatherService.icon
    text: WeatherService.ready ? (WeatherService.temp + "°C") : "--°C"
    monospace: true
}
