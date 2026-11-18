pragma Singleton

import QtQuick
import Quickshell

// Global weather service (polls wttr.in every 15 minutes)
Singleton {
    id: root

    property string temp: "--"
    property string feelsLike: "--"
    property string condition: ""
    property string humidity: "--"
    property string windKmph: "--"
    property string city: ""
    property string weatherCode: ""
    property bool ready: false

    // Map wttr.in WWO weather codes to Nerd Font icons
    readonly property string icon: {
        const code = parseInt(weatherCode);
        if (code === 113) return "󰖙"; // Clear / Sunny
        if (code === 116) return "󰖕"; // Partly cloudy
        if (code === 119 || code === 122) return "󰖐"; // Cloudy / Overcast
        if (code === 143 || code === 248 || code === 260) return "󰖑"; // Fog / Mist
        if ([200, 386, 389, 392, 395].includes(code)) return "󰖓"; // Thunderstorm
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code)) return "󰖘"; // Snow / Sleet
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].includes(code)) return "󰖗"; // Rain / Drizzle
        return "󰖐";
    }

    function refresh() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const current = data.current_condition[0];
                    const area = data.nearest_area?.[0];
                    root.temp = current.temp_C ?? "--";
                    root.feelsLike = current.FeelsLikeC ?? "--";
                    root.condition = current.weatherDesc?.[0]?.value ?? "";
                    root.humidity = current.humidity ?? "--";
                    root.windKmph = current.windspeedKmph ?? "--";
                    root.city = area?.areaName?.[0]?.value ?? "";
                    root.weatherCode = current.weatherCode ?? "";
                    root.ready = true;
                } catch (e) {
                    // Keep the last valid reading if parsing fails
                }
            }
        };
        xhr.open("GET", "https://wttr.in/?format=j1");
        xhr.send();
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
