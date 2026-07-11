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

    // shared tooltip popup
    Rectangle {
        id: tooltip
        visible: false
        parent: root
        z: 999
        color: Theme.background
        border.color: Theme.barBorder
        border.width: 1
        radius: 6
        width: tooltipCol.implicitWidth + 16
        height: tooltipCol.implicitHeight + 10
        property string title: ""
        property string subtitle: ""

        function showFor(icon, item) {
            title = item.title ?? ""
            subtitle = item.tooltipSubtitle ?? item.status ?? ""
            // position centred below the icon
            const pos = icon.mapToItem(root, 0, 0)
            x = Math.max(0, Math.min(pos.x + icon.width / 2 - width / 2, root.width - width))
            y = pos.y + icon.height + 6
            visible = true
        }

        function hide() {
            visible = false
        }

        ColumnLayout {
            id: tooltipCol
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: tooltip.title
                color: Theme.foreground
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                visible: text !== ""
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: tooltip.subtitle
                color: Theme.mutedForeground ?? Theme.foreground
                font.pixelSize: Theme.fontSize - 1
                visible: text !== ""
                Layout.alignment: Qt.AlignHCenter
            }
        }
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

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onEntered: tooltip.showFor(trayIcon, trayIcon.modelData)
                onExited: tooltip.hide()

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
