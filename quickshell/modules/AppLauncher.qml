import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../config"

// Application launcher (toggled via SUPER + F -> qs ipc call launcher toggle)
PanelWindow {
    id: root

    property bool isOpen: false
    property bool showOnlyFavorites: true
    property bool isGridView: false
    property int currentIndex: 0
    property string menuAppId: ""
    property bool menuOpen: false

    onIsOpenChanged: {
        if (!isOpen) {
            menuOpen = false;
        }
    }

    readonly property int gridColumns: 3

    function open() {
        menuOpen = false;
        search.clear();
        showOnlyFavorites = true;
        currentIndex = 0;
        isOpen = true;
        search.focusInput();
    }

    function toggle() {
        if (isOpen) {
            isOpen = false;
            menuOpen = false;
        } else {
            open();
        }
    }

    function openContextMenu(appId, itemY) {
        menuAppId = appId;
        const maxY = surface.height - contextMenu.height - Properties.sizes.overlayPadding;
        contextMenu.y = Math.max(Properties.sizes.overlayPadding, Math.min(itemY, maxY));
        menuOpen = true;
    }

    // Favorites preserve custom order; All / search results are sorted alphabetically
    readonly property var filteredApps: {
        const query = search.text.trim().toLowerCase();
        const all = DesktopEntries.applications.values.filter(app => !app.noDisplay);

        if (showOnlyFavorites && query === "") {
            const byId = new Map(all.map(app => [app.id, app]));
            return Favorites.apps.map(id => byId.get(id)).filter(Boolean);
        }

        const list = query === ""
            ? all
            : all.filter(app => app.name.toLowerCase().includes(query));

        return list.slice().sort((a, b) => a.name.localeCompare(b.name));
    }

    function moveSelection(step) {
        const count = filteredApps.length;
        if (count === 0) return;
        currentIndex = (currentIndex + step + count) % count;
        if (isGridView) {
            appGrid.positionViewAtIndex(currentIndex, GridView.Contain);
        } else {
            appList.positionViewAtIndex(currentIndex, ListView.Contain);
        }
    }

    function launchCurrent() {
        if (currentIndex >= 0 && currentIndex < filteredApps.length) {
            filteredApps[currentIndex].execute();
            isOpen = false;
            menuOpen = false;
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: isOpen || surface.opacity > 0
    focusable: isOpen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggle(); }
    }

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color: "#44000000"
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
    }

    // Close on outside click
    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: {
            root.menuOpen = false;
            root.isOpen = false;
        }
    }

    Surface {
        id: surface
        anchors.centerIn: parent
        width: Properties.sizes.launcherWidth
        height: Properties.sizes.launcherHeight
        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Properties.animation.normal; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: Properties.sizes.overlayPadding
            spacing: Properties.spacing.overlayGap

            SearchInput {
                id: search
                width: parent.width
                placeholder: "Search applications"
                onEscapePressed: {
                    if (root.menuOpen) {
                        root.menuOpen = false;
                    } else {
                        root.isOpen = false;
                    }
                }
                onAccepted: root.launchCurrent()
                onMoveUp: root.moveSelection(root.isGridView ? -root.gridColumns : -1)
                onMoveDown: root.moveSelection(root.isGridView ? root.gridColumns : 1)
                onMoveLeft: {
                    if (root.isGridView) root.moveSelection(-1);
                }
                onMoveRight: {
                    if (root.isGridView) root.moveSelection(1);
                }
                onTabPressed: {
                    root.menuOpen = false;
                    root.showOnlyFavorites = !root.showOnlyFavorites;
                    root.currentIndex = 0;
                }
                onTextChanged: {
                    root.menuOpen = false;
                    root.currentIndex = 0;
                }
            }

            // Tabs (Favorites / All) + List/Grid view toggle on the right
            Item {
                id: tabsBar
                width: parent.width
                height: Properties.sizes.tabHeight

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Favorites", onlyFavs: true },
                            { label: "All",       onlyFavs: false }
                        ]

                        Rectangle {
                            required property var modelData
                            readonly property bool active: root.showOnlyFavorites === modelData.onlyFavs

                            implicitWidth: tabText.implicitWidth + 20
                            implicitHeight: Properties.sizes.tabHeight
                            radius: Properties.radius.medium
                            color: active
                                ? Properties.colors.accent
                                : (tabMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground)

                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Properties.colors.textOnAccent : Properties.colors.text
                                font.family: Properties.typography.fontFamily
                                font.pixelSize: Properties.typography.fontSizeSmall
                                font.bold: active
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.menuOpen = false;
                                    root.showOnlyFavorites = modelData.onlyFavs;
                                    root.currentIndex = 0;
                                    search.focusInput();
                                }
                            }
                        }
                    }
                }

                // Toggle between List and Grid view
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Properties.sizes.tabHeight
                    height: Properties.sizes.tabHeight
                    radius: Properties.radius.medium
                    color: viewMouse.containsMouse ? Properties.colors.moduleHover : Properties.colors.moduleBackground

                    Text {
                        anchors.centerIn: parent
                        text: root.isGridView ? "󰕱" : "󰝘"
                        color: Properties.colors.text
                        font.family: Properties.typography.iconFamily
                        font.pixelSize: Properties.typography.iconSize
                    }

                    MouseArea {
                        id: viewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.menuOpen = false;
                            root.isGridView = !root.isGridView;
                            search.focusInput();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.height - search.height - tabsBar.height - Properties.spacing.overlayGap * 2

                // List View
                ListView {
                    id: appList
                    anchors.fill: parent
                    visible: !root.isGridView
                    clip: true
                    spacing: Properties.spacing.listGap
                    model: root.filteredApps
                    currentIndex: root.currentIndex

                    delegate: Rectangle {
                        id: listRow
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.currentIndex

                        width: appList.width
                        height: Properties.sizes.optionHeight
                        radius: Properties.radius.medium
                        color: {
                            if (isSelected) return Properties.colors.accent;
                            if (listMouse.containsMouse || listMoreMouse.containsMouse) return Properties.colors.moduleHover;
                            return "transparent";
                        }

                        Behavior on color {
                            ColorAnimation { duration: Properties.animation.fast }
                        }

                        MouseArea {
                            id: listMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    const pos = listRow.mapToItem(surface, 0, listRow.height);
                                    root.openContextMenu(listRow.modelData.id, pos.y);
                                } else {
                                    root.menuOpen = false;
                                    listRow.modelData.execute();
                                    root.isOpen = false;
                                }
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10

                            IconImage {
                                id: listIconImg
                                anchors.verticalCenter: parent.verticalCenter
                                readonly property string resolvedSource: listRow.modelData.icon ? Quickshell.iconPath(listRow.modelData.icon, true) : ""
                                visible: resolvedSource !== ""
                                source: resolvedSource
                                implicitSize: Properties.sizes.listIconSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !listIconImg.visible
                                text: "󰣆"
                                color: listRow.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                font.family: Properties.typography.iconFamily
                                font.pixelSize: Properties.sizes.listIconSize - 6
                                width: Properties.sizes.listIconSize
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - Properties.sizes.listIconSize - Properties.px(52)
                                text: listRow.modelData.name ?? ""
                                elide: Text.ElideRight
                                color: listRow.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                font.family: Properties.typography.fontFamily
                                font.pixelSize: Properties.typography.fontSizeLarge
                                font.bold: listRow.isSelected
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Properties.px(32)
                                height: Properties.px(32)
                                radius: Properties.radius.small
                                visible: listMouse.containsMouse || listMoreMouse.containsMouse || (root.menuOpen && root.menuAppId === listRow.modelData.id)
                                color: listMoreMouse.containsMouse ? Properties.colors.moduleBackground : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰇙"
                                    color: listRow.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.px(18)
                                }

                                MouseArea {
                                    id: listMoreMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const pos = listRow.mapToItem(surface, 0, listRow.height);
                                        root.openContextMenu(listRow.modelData.id, pos.y);
                                    }
                                }
                            }
                        }
                    }
                }

                // Grid View
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    visible: root.isGridView
                    clip: true
                    cellWidth: Math.floor(width / root.gridColumns)
                    cellHeight: Properties.sizes.gridCellHeight
                    model: root.filteredApps
                    currentIndex: root.currentIndex

                    delegate: Item {
                        id: gridCell
                        required property var modelData
                        required property int index

                        width: appGrid.cellWidth
                        height: appGrid.cellHeight

                        readonly property bool isSelected: index === root.currentIndex

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Properties.radius.medium
                            color: {
                                if (gridCell.isSelected) return Properties.colors.accent;
                                if (gridMouse.containsMouse || gridMoreMouse.containsMouse) return Properties.colors.moduleHover;
                                return "transparent";
                            }

                            Behavior on color {
                                ColorAnimation { duration: Properties.animation.fast }
                            }

                            MouseArea {
                                id: gridMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        const pos = gridCell.mapToItem(surface, 0, gridCell.height);
                                        root.openContextMenu(gridCell.modelData.id, pos.y);
                                    } else {
                                        root.menuOpen = false;
                                        gridCell.modelData.execute();
                                        root.isOpen = false;
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                spacing: 6

                                IconImage {
                                    id: gridIconImg
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    readonly property string resolvedSource: gridCell.modelData.icon ? Quickshell.iconPath(gridCell.modelData.icon, true) : ""
                                    visible: resolvedSource !== ""
                                    source: resolvedSource
                                    implicitSize: Properties.sizes.gridIconSize
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: !gridIconImg.visible
                                    text: "󰣆"
                                    color: gridCell.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.sizes.gridIconSize - 6
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: gridCell.modelData.name ?? ""
                                    elide: Text.ElideRight
                                    color: gridCell.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                    font.family: Properties.typography.fontFamily
                                    font.pixelSize: Properties.typography.fontSize
                                    font.bold: gridCell.isSelected
                                }
                            }

                            // Mini-menu button in top-right corner of the grid tile
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                width: Properties.px(24)
                                height: Properties.px(24)
                                radius: Properties.radius.small
                                visible: gridMouse.containsMouse || gridMoreMouse.containsMouse || (root.menuOpen && root.menuAppId === gridCell.modelData.id)
                                color: gridMoreMouse.containsMouse ? Properties.colors.moduleBackground : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰇙"
                                    color: gridCell.isSelected ? Properties.colors.textOnAccent : Properties.colors.text
                                    font.family: Properties.typography.iconFamily
                                    font.pixelSize: Properties.px(16)
                                }

                                MouseArea {
                                    id: gridMoreMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const pos = gridCell.mapToItem(surface, 0, gridCell.height);
                                        root.openContextMenu(gridCell.modelData.id, pos.y);
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.filteredApps.length === 0
                    text: root.showOnlyFavorites && Favorites.apps.length === 0
                        ? "No favorites yet — right-click any app in All to add"
                        : "No applications found"
                    color: Properties.colors.textMuted
                    font.family: Properties.typography.fontFamily
                    font.pixelSize: Properties.typography.fontSize
                }
            }
        }

        // Click-away overlay to dismiss the mini context menu
        MouseArea {
            anchors.fill: parent
            visible: root.menuOpen
            onClicked: root.menuOpen = false
        }

        // Mini context menu for Favorites & custom ordering
        Surface {
            id: contextMenu
            visible: root.menuOpen
            x: surface.width - width - Properties.sizes.overlayPadding
            width: Properties.sizes.contextMenuWidth
            height: menuCol.implicitHeight + 12

            readonly property bool targetIsFav: Favorites.isFavorite(root.menuAppId)
            readonly property int favIdx: Favorites.apps.indexOf(root.menuAppId)
            readonly property bool canReorder: root.showOnlyFavorites && search.text.trim() === "" && targetIsFav

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                OptionItem {
                    width: parent.width
                    height: Properties.sizes.contextMenuItemHeight
                    icon: contextMenu.targetIsFav ? "☆" : "★"
                    title: contextMenu.targetIsFav ? "Remove from Favorites" : "Add to Favorites"
                    onTriggered: {
                        Favorites.toggle(root.menuAppId);
                        root.menuOpen = false;
                        search.focusInput();
                    }
                }

                OptionItem {
                    width: parent.width
                    height: Properties.sizes.contextMenuItemHeight
                    visible: contextMenu.canReorder && contextMenu.favIdx > 0
                    icon: "↑"
                    title: "Move Up"
                    onTriggered: {
                        Favorites.move(root.menuAppId, -1);
                        root.menuOpen = false;
                        search.focusInput();
                    }
                }

                OptionItem {
                    width: parent.width
                    height: Properties.sizes.contextMenuItemHeight
                    visible: contextMenu.canReorder && contextMenu.favIdx >= 0 && contextMenu.favIdx < Favorites.apps.length - 1
                    icon: "↓"
                    title: "Move Down"
                    onTriggered: {
                        Favorites.move(root.menuAppId, 1);
                        root.menuOpen = false;
                        search.focusInput();
                    }
                }
            }
        }
    }
}
