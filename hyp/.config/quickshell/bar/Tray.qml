import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Tray icons shown inline in the bar — one slot per app, right-click for menu.
RowLayout {
    id: root
    property color foreground: Theme.foreground
    spacing: Theme.moduleSpacing
    visible: SystemTray.items.values.length > 0
    Layout.alignment: Qt.AlignVCenter
    property var hoveredItem: null

    TrayMenuPopup { id: trayMenu }

    BarTooltip {
        id: tip
        contentWidth: Math.min(480, (screen?.width ?? 1920) - 16,
            labelMetrics.width + 24)
        contentHeight: tipText.paintedHeight + 14
        TextMetrics {
            id: labelMetrics
            font: tipText.font
            text: tipText.text
        }
        Text {
            id: tipText
            anchors.centerIn: parent
            width: parent.width - 24
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.PlainText
            text: root.hoveredItem?.tooltipTitle || root.hoveredItem?.title
                || root.hoveredItem?.id || ""
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.foreground
        }
    }

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
                color:        mo.containsMouse ? Qt.alpha(root.foreground, 0.13) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitWidth:    Theme.iconSize
                implicitHeight:   Theme.iconSize
                source:           trayItem.modelData.icon
            }

            BarHitArea {
                id:              mo
                slackX:          0
                hoverEnabled:    true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: {
                    root.hoveredItem = trayItem.modelData
                    tip.show(trayItem)
                }
                onExited: tip.hide()
                onClicked: mouse => {
                    tip.hide()
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
