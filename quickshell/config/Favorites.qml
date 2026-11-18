pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent list of favorite DesktopEntry IDs (stored in config/favorites.json)
Singleton {
    id: root

    property var apps: []

    readonly property string filePath: Qt.resolvedUrl("favorites.json").toString().replace(/^file:\/\//, "")

    function loadFromText(raw) {
        try {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
                root.apps = parsed;
            }
        } catch (e) {
            // Keep current list if JSON is malformed
        }
    }

    function save() {
        favFile.setText(JSON.stringify(root.apps, null, 4) + "\n");
    }

    function isFavorite(id) {
        return root.apps.includes(id);
    }

    function add(id) {
        if (!id || isFavorite(id)) return;
        root.apps = root.apps.concat([id]);
        save();
    }

    function remove(id) {
        if (!isFavorite(id)) return;
        root.apps = root.apps.filter(item => item !== id);
        save();
    }

    function toggle(id) {
        if (isFavorite(id)) remove(id);
        else add(id);
    }

    function move(id, delta) {
        const idx = root.apps.indexOf(id);
        const target = idx + delta;
        if (idx < 0 || target < 0 || target >= root.apps.length) return;

        const copy = root.apps.slice();
        const item = copy.splice(idx, 1)[0];
        copy.splice(target, 0, item);
        root.apps = copy;
        save();
    }

    FileView {
        id: favFile
        path: root.filePath
        preload: true
        watchChanges: true
        onLoaded: root.loadFromText(favFile.text())
        onFileChanged: favFile.reload()
    }
}
