pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "../config"

// Global notification server managing stacked popups, countdowns, and history
Singleton {
    id: root

    // Each popup entry: { notif, totalMs, remainingMs, paused }
    property var popups: []
    property var history: []
    property bool dnd: Properties.dnd

    onDndChanged: {
        if (Properties.dnd !== dnd) {
            Properties.setDnd(dnd);
        }
        if (dnd) {
            popups = [];
        }
    }

    Connections {
        target: Properties
        function onDndChanged() {
            if (root.dnd !== Properties.dnd) {
                root.dnd = Properties.dnd;
            }
        }
    }

    readonly property int defaultTimeout: 5000
    readonly property int maxPopups: 4

    function addNotification(notif) {
        notif.tracked = true;
        const timeout = (notif.expireTimeout > 0) ? notif.expireTimeout : defaultTimeout;

        // Deduplicate if an identical popup (same id or same appName+summary+body) is already visible
        const existingIdx = popups.findIndex(entry =>
            entry.notif === notif
            || (entry.notif.id !== undefined && entry.notif.id === notif.id)
            || (entry.notif.appName === notif.appName
                && entry.notif.summary === notif.summary
                && entry.notif.body === notif.body)
        );

        if (existingIdx >= 0) {
            const copy = popups.slice();
            copy[existingIdx] = {
                notif: notif,
                totalMs: timeout,
                remainingMs: timeout,
                paused: copy[existingIdx].paused
            };
            popups = copy;
            return;
        }

        history = [notif].concat(history);

        if (!dnd) {
            const entry = {
                notif: notif,
                totalMs: timeout,
                remainingMs: timeout,
                paused: false
            };
            popups = [entry].concat(popups).slice(0, maxPopups);
        }
    }

    function setPopupPaused(notif, isPaused) {
        for (let i = 0; i < popups.length; i++) {
            if (popups[i].notif === notif) {
                popups[i].paused = isPaused;
                break;
            }
        }
    }

    function dismissPopup(notif) {
        popups = popups.filter(entry => entry.notif !== notif);
    }

    function closeNotification(notif) {
        popups = popups.filter(entry => entry.notif !== notif);
        history = history.filter(n => n !== notif);
        notif.dismiss();
    }

    function clearHistory() {
        history.forEach(n => n.dismiss());
        popups = [];
        history = [];
    }

    function focusApp(notif) {
        const defaultAction = notif.actions.find(a => a.identifier === "default");
        if (defaultAction) {
            defaultAction.invoke();
        }

        const target = (notif.appName || "").toLowerCase();
        if (target !== "") {
            const win = Hyprland.toplevels.values.find(t => {
                const cls = (t.lastIpcObject?.class ?? "").toLowerCase();
                const title = (t.title ?? "").toLowerCase();
                return cls.includes(target) || target.includes(cls) || title.includes(target);
            });

            if (win) {
                const addr = win.address.startsWith("0x") ? win.address : ("0x" + win.address);
                const cmd = Hyprland.usingLua
                    ? "hl.dsp.focus({ window = \"address:" + addr + "\" })"
                    : "focuswindow address:" + addr;
                Hyprland.dispatch(cmd);
            }
        }

        dismissPopup(notif);
    }

    // Single centralized timer so stacked popups never reset or get stuck
    Timer {
        interval: 50
        running: root.popups.length > 0
        repeat: true
        onTriggered: {
            let changed = false;
            const next = [];
            for (let i = 0; i < root.popups.length; i++) {
                const entry = root.popups[i];
                if (!entry.paused) {
                    entry.remainingMs -= 50;
                }
                if (entry.remainingMs > 0) {
                    next.push(entry);
                } else {
                    changed = true;
                }
            }
            if (changed) {
                root.popups = next;
            } else {
                // Trigger property binding update for progress bars
                root.popupsChanged();
            }
        }
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notif => root.addNotification(notif)
    }
}
