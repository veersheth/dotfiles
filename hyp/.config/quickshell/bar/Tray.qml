import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.bar.popups

// Tray icons shown inline in the bar — one slot per app, right-click for menu.
RowLayout {
    id: root
    spacing: 122
    visible: SystemTray.items.values.length > 0
    Layout.alignment: Qt.AlignVCenter

    TrayMenuPopup { id: trayMenu }

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            required property var modelData

            Layout.alignment:    Qt.AlignVCenter
            implicitWidth:       Theme.iconSlot
            implicitHeight:      Theme.pillHeight

            Rectangle {
                anchors.fill: parent
                radius:       height / 2
                color:        mo.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitWidth:    Theme.iconSize
                implicitHeight:   Theme.iconSize
                source:           trayItem.modelData.icon
            }

            MouseArea {
                id:              mo
                anchors.fill:    parent
                hoverEnabled:    true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    const item = trayItem.modelData
                    if (mouse.button === Qt.RightButton) {
                        if (item.hasMenu) trayMenu.openFor(trayItem, item.menu)
                    } else if (item.onlyMenu) {
                        if (item.hasMenu) trayMenu.openFor(trayItem, item.menu)
                    } else {
                        item.activate()
                    }
                }
            }
        }
    }
}
