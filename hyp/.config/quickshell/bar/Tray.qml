import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.bar.popups

// System tray icons; left click activates, right click opens the menu.
RowLayout {
    id: root
    visible: SystemTray.items.values.length > 0
    spacing: 8

    // one shared menu popup, re-anchored to whichever icon opened it
    TrayMenuPopup {
        id: trayMenu
    }

    Repeater {
        model: SystemTray.items

        IconImage {
            id: trayIcon
            required property var modelData

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 16
            implicitHeight: 16
            source: modelData.icon
            opacity: mouse.containsMouse ? 1.0 : 0.85

            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !trayIcon.modelData.onlyMenu)
                        trayIcon.modelData.activate();
                    else if (trayIcon.modelData.hasMenu)
                        trayMenu.openFor(trayIcon, trayIcon.modelData.menu);
                }
            }
        }
    }
}
