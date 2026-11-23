import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Unpinned apps live in overflow; dragging them to the bar pins them.
Item {
    id: root
    property color foreground: Theme.foreground
    readonly property var items: SystemTray.items.values
    readonly property var pinnedItems: items.filter(item => TrayPins.isPinned(item))
        .sort((a, b) => TrayPins.pinnedIds.indexOf(a.id) - TrayPins.pinnedIds.indexOf(b.id))
    readonly property var hiddenItems: items.filter(item => !TrayPins.isPinned(item))
    readonly property bool showOverflowArrow: root.hiddenItems.length > 0 || root.dragItem !== null
    property var hoveredItem: null
    property var dragItem: null
    property bool dragFromOverflow: false
    property real dragScreenX: 0
    property real dragScreenY: 0
    property real markerX: 0
    property bool showMarker: false
    property bool autoOpenedOverflow: false
    property double lastDropAt: 0

    visible: items.length > 0
    implicitWidth: trayRow.implicitWidth
    implicitHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter

    function barOriginX() { return root.QsWindow.window?.screen?.x ?? 0 }
    function barOriginY() {
        const screen = root.QsWindow.window?.screen
        return (screen?.y ?? 0)
            + (BarState.barBottom ? (screen?.height ?? 0) - Theme.barHeight : 0)
    }
    function popupOriginX() {
        return (overflow.screen?.x ?? 0) + overflow.WlrLayershell.margins.left
    }
    function popupOriginY() {
        return (overflow.screen?.y ?? 0)
            + (BarState.barBottom ? 8 : Theme.barHeight)
    }

    function inBar(x, y) {
        const screen = root.QsWindow.window?.screen
        if (!screen) return false
        const sx = screen.x ?? 0, sy = screen.y ?? 0
        const top = sy + (BarState.barBottom ? screen.height - Theme.barHeight : 0)
        return x >= sx && x < sx + screen.width && y >= top && y < top + Theme.barHeight
    }

    function containsOnScreen(item, x, y, surfaceX, surfaceY) {
        const topLeft = item.mapToItem(null, 0, 0)
        const localX = x - surfaceX - topLeft.x
        const localY = y - surfaceY - topLeft.y
        return localX >= 0 && localX < item.width && localY >= 0 && localY < item.height
    }

    function inOverflow(x, y) {
        return containsOnScreen(overflowButton, x, y, barOriginX(), barOriginY())
            || (overflow.shown && containsOnScreen(popupContents, x, y,
                popupOriginX(), popupOriginY()))
    }

    function insertionAt(x) {
        for (let i = 0; i < pinnedRepeater.count; ++i) {
            const icon = pinnedRepeater.itemAt(i)
            if (!icon || icon.modelData.id === dragItem?.id) continue
            const middle = barOriginX() + icon.mapToItem(null, icon.width / 2, 0).x
            if (x < middle) {
                markerX = icon.mapToItem(root, 0, 0).x
                return TrayPins.pinnedIds.indexOf(icon.modelData.id)
            }
        }
        markerX = trayRow.x + trayRow.width
        return TrayPins.pinnedIds.length
    }

    function beginDrag(item, fromOverflow, x, y) {
        dragItem = item
        dragFromOverflow = fromOverflow
        if (!fromOverflow && !overflow.shown) {
            autoOpenedOverflow = true
            overflow.shown = true
        }
        tip.hide()
        updateDrag(x, y)
    }

    function updateDrag(x, y) {
        if (!dragItem) return
        dragScreenX = x
        dragScreenY = y
        showMarker = inBar(x, y) && !inOverflow(x, y)
        if (showMarker) insertionAt(x)
    }

    function finishDrag(x, y) {
        if (!dragItem) return
        const id = dragItem.id
        updateDrag(x, y)
        if (!dragFromOverflow && inOverflow(x, y)) {
            TrayPins.unpin(id)
        } else if (inBar(x, y) && !inOverflow(x, y)) {
            TrayPins.place(id, insertionAt(x))
        }
        dragItem = null
        showMarker = false
        lastDropAt = Date.now()
        if (autoOpenedOverflow) {
            autoOpenedOverflow = false
            overflow.shown = false
        }
    }

    function cancelDrag() {
        dragItem = null
        showMarker = false
        if (autoOpenedOverflow) {
            autoOpenedOverflow = false
            overflow.shown = false
        }
    }

    function activateIcon(source, item, button) {
        if (Date.now() - lastDropAt < 120) return
        tip.hide()
        if (button === Qt.RightButton || item.onlyMenu) {
            if (item.hasMenu)
                trayMenu.openFor(source.inOverflow ? overflowButton : source, item.menu)
        } else {
            item.activate()
        }
    }

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
                || root.hoveredItem?.id || "System tray"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.foreground
        }
    }

    RowLayout {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.moduleSpacing

        Item {
            id: overflowButton
            visible: root.showOverflowArrow
            implicitWidth: Theme.iconSlot
            implicitHeight: Theme.pillHeight
            Accessible.name: "System tray"
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.dragItem && root.inOverflow(root.dragScreenX, root.dragScreenY)
                    ? Qt.alpha(Theme.blue, 0.25)
                    : overflowMouse.containsMouse ? Qt.alpha(root.foreground, 0.13) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: "󰅀"
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize
                color: root.foreground
                rotation: overflow.shown ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.animDuration } }
            }
            BarHitArea {
                id: overflowMouse
                slackX: 0
                hoverEnabled: true
                onEntered: {
                    root.hoveredItem = null
                    tip.show(overflowButton)
                }
                onExited: tip.hide()
                onClicked: { tip.hide(); overflow.toggle() }
            }
        }

        Repeater {
            id: pinnedRepeater
            model: root.pinnedItems
            TrayEntry {
                id: pinnedIcon
                inOverflow: false
                foreground: root.foreground
                surfaceX: root.barOriginX()
                surfaceY: root.barOriginY()
                dragging: root.dragItem?.id === modelData.id
                onActivated: (item, button) => root.activateIcon(pinnedIcon, item, button)
                onHoverEntered: item => { root.hoveredItem = item; tip.show(pinnedIcon) }
                onHoverExited: tip.hide()
                onDragStarted: (item, x, y) => root.beginDrag(item, false, x, y)
                onDragMoved: (x, y) => root.updateDrag(x, y)
                onDragFinished: (x, y) => root.finishDrag(x, y)
                onDragCanceled: root.cancelDrag()
            }
        }
    }

    Rectangle {
        visible: root.dragItem !== null && root.showMarker
        x: root.markerX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Theme.pillHeight
        radius: width / 2
        color: Theme.blue
    }

    BarPopup {
        id: overflow
        anchorItem: overflowButton
        grabFocus: root.dragItem === null
        dismissOnOutsideClick: root.dragItem === null
        contentWidth: 264
        contentPadding: 12
        contentHeight: popupContents.implicitHeight + 2 * contentPadding

        Item {
            id: popupContents
            anchors { left: parent.left; right: parent.right; top: parent.top }
            implicitHeight: root.hiddenItems.length > 0 ? hiddenList.implicitHeight : 40
            CommonList {
                id: hiddenList
                visible: root.hiddenItems.length > 0
                width: parent.width
                spacing: 0
                Repeater {
                    model: root.hiddenItems
                    TrayEntry {
                        id: hiddenIcon
                        inOverflow: true
                        foreground: root.foreground
                        surfaceX: root.popupOriginX()
                        surfaceY: root.popupOriginY()
                        dragging: root.dragItem?.id === modelData.id
                        onActivated: (item, button) => root.activateIcon(hiddenIcon, item, button)
                        onHoverEntered: item => { root.hoveredItem = item }
                        onHoverExited: tip.hide()
                        onDragStarted: (item, x, y) => root.beginDrag(item, true, x, y)
                        onDragMoved: (x, y) => root.updateDrag(x, y)
                        onDragFinished: (x, y) => root.finishDrag(x, y)
                        onDragCanceled: root.cancelDrag()
                    }
                }
            }
            Text {
                visible: root.hiddenItems.length === 0
                anchors.centerIn: parent
                text: "󰅀"
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize
                color: Qt.alpha(Theme.foreground, 0.4)
            }
        }
    }

    PanelWindow {
        id: dragGhost
        visible: root.dragItem !== null
        screen: root.QsWindow.window?.screen ?? null
        anchors.top: true
        anchors.left: true
        exclusiveZone: -1
        implicitWidth: screen?.width ?? 1
        implicitHeight: screen?.height ?? 1
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "quickshell:tray-drag"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Rectangle {
            x: Math.round(root.dragScreenX - (dragGhost.screen?.x ?? 0) - width / 2)
            y: Math.round(root.dragScreenY - (dragGhost.screen?.y ?? 0) - height / 2)
            width: 44
            height: 44
            radius: height / 2
            color: Theme.surface
            border.color: Theme.blue
            border.width: Theme.borderWidth
            IconImage {
                anchors.centerIn: parent
                implicitWidth: Theme.iconSize
                implicitHeight: Theme.iconSize
                source: root.dragItem?.icon ?? ""
            }
        }
    }
}
