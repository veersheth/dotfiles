import Quickshell
import QtQuick
import qs.common
import qs.components

// Shared context menu for the bar and the desktop, with grouped options.
BarPopup {
    id: root

    contentWidth: 246
    contentHeight: menuCol.implicitHeight + 2 * root.contentPadding

    Column {
        id: menuCol
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
        spacing: 4

        Text {
            width: parent.width
            text: "APPEARANCE"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.45)
        }

        MenuRow {
            icon: "󰸉"
            label: "Change background…"
            onTriggered: { root.close(); BarState.requestWallpaperPicker() }
        }

        MenuRow {
            icon: "󰏘"
            label: "Set solid color…"
            onTriggered: { root.close(); BarState.requestColorPicker() }
        }

        MenuRow {
            label: "Transparent bar"
            checkable: true
            checked: BarState.transparent
            onTriggered: { BarState.setTransparent(!BarState.transparent); root.close() }
        }

        Item { width: parent.width; height: 6 }

        Text {
            width: parent.width
            text: "BAR"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.45)
        }

        MenuRow {
            icon: BarState.barBottom ? "󰹙" : "󰹘"
            label: BarState.barBottom ? "Move bar to top" : "Move bar to bottom"
            onTriggered: { root.close(); BarState.setBottom(!BarState.barBottom) }
        }

        MenuRow {
            label: "Auto-hide bar"
            checkable: true
            checked: BarState.barAutoHide
            onTriggered: { root.close(); BarState.toggleBarAutoHide() }
        }

        MenuRow {
            label: "Rearrange modules"
            checkable: true
            checked: BarState.rearrangeModules
            onTriggered: { root.close(); BarState.toggleRearrangeModules() }
        }

        Item { width: parent.width; height: 6 }

        Text {
            width: parent.width
            text: "DOCK"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.45)
        }

        MenuRow {
            icon: "󰋙"
            label: "Auto-hide dock"
            checkable: true
            checked: DockState.dockAutoHide
            onTriggered: { root.close(); DockState.toggleDockAutoHide() }
        }
    }
}
