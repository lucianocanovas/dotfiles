import QtQuick
import Quickshell

import "daemons"
import "modules"

ShellRoot {
    id: root

    function closeAllExcept(activeItem) {
        const overlays = [barPopups, sidebar, generalMenu, appLauncher, settingsWindow, powerMenu, altTabMenu];
        for (let i = 0; i < overlays.length; i++) {
            const item = overlays[i];
            if (item !== activeItem && item.isOpen) {
                item.isOpen = false;
            }
        }
    }

    // Background daemons
    PolkitDaemon {}
    IdleDaemon {
        onLockRequested: {
            root.closeAllExcept(null);
            lockScreen.lock();
        }
    }
    AlertsDaemon {}

    // Top bar & popups
    Bar {
        sidebarOpen: sidebar.isOpen
        activePopup: barPopups.isOpen ? barPopups.activePopup : ""
        onToggleSidebar: sidebar.toggle()
        onTogglePopup: (name, centerX) => barPopups.toggle(name, centerX)
    }

    BarPopups {
        id: barPopups
        onIsOpenChanged: if (isOpen) root.closeAllExcept(barPopups)
    }

    Sidebar {
        id: sidebar
        onIsOpenChanged: if (isOpen) root.closeAllExcept(sidebar)
        onOpenLauncher: appLauncher.open()
        onOpenSettings: settingsWindow.open()
        onOpenPowerMenu: powerMenu.open()
    }

    // Overlays & menus
    GeneralMenu {
        id: generalMenu
        onIsOpenChanged: if (isOpen) root.closeAllExcept(generalMenu)
        onOpenLauncher: appLauncher.open()
        onOpenSettings: settingsWindow.open()
        onOpenPowerMenu: powerMenu.open()
    }

    AppLauncher {
        id: appLauncher
        onIsOpenChanged: if (isOpen) root.closeAllExcept(appLauncher)
    }

    Settings {
        id: settingsWindow
        onIsOpenChanged: if (isOpen) root.closeAllExcept(settingsWindow)
    }

    PowerMenu {
        id: powerMenu
        onIsOpenChanged: if (isOpen) root.closeAllExcept(powerMenu)
    }

    AltTabMenu {
        id: altTabMenu
        onIsOpenChanged: if (isOpen) root.closeAllExcept(altTabMenu)
    }

    Notifications {}

    Osd {}

    LockScreen {
        id: lockScreen
    }
}
