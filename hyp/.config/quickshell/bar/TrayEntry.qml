import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

Item {
    id: root
    required property var modelData
    property bool inOverflow: false
    property bool dragging: false
    property color foreground: Theme.foreground
    property real surfaceX: 0
    property real surfaceY: 0
    signal activated(var item, var button)
    signal hoverEntered(var item)
    signal hoverExited()
    signal dragStarted(var item, real x, real y)
    signal dragMoved(real x, real y)
    signal dragFinished(real x, real y)
    signal dragCanceled()

    implicitWidth: root.inOverflow ? 240 : Theme.iconSlot
    implicitHeight: root.inOverflow ? 40 : Theme.pillHeight
    Layout.fillWidth: root.inOverflow
    opacity: root.dragging ? 0.35 : 1
    Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id

    // ── Bar icon (compact, no label) ─────────────────────────────────────
    Item {
        visible: !root.inOverflow
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: barMouse.containsMouse ? Qt.alpha(root.foreground, 0.13) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSize
            source: root.modelData.icon
        }
        BarHitArea {
            id: barMouse
            property real pressX: 0
            property real pressY: 0
            property bool dragging: false
            slackX: 0
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: root.hoverEntered(root.modelData)
            onExited: root.hoverExited()
            onClicked: mouse => root.activated(root.modelData, mouse.button)
            onPressed: mouse => {
                pressX = mouse.x;
                pressY = mouse.y;
                dragging = false;
            }
            onPositionChanged: mouse => {
                if (!(mouse.buttons & Qt.LeftButton)) return;
                if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) < 8) return;
                const scene = barMouse.mapToItem(null, mouse.x, mouse.y);
                const screenX = root.surfaceX + scene.x;
                const screenY = root.surfaceY + scene.y;
                if (!dragging) {
                    dragging = true;
                    root.dragStarted(root.modelData, screenX, screenY);
                }
                root.dragMoved(screenX, screenY);
            }
            onReleased: mouse => {
                if (!dragging) return;
                const scene = barMouse.mapToItem(null, mouse.x, mouse.y);
                dragging = false;
                root.dragFinished(root.surfaceX + scene.x, root.surfaceY + scene.y);
            }
            onCanceled: {
                const wasDragging = dragging;
                dragging = false;
                if (wasDragging) root.dragCanceled();
            }
        }
    }

    // ── Overflow row (shared popup list styling) ─────────────────────────
    PopupListRow {
        id: overflowRow
        visible: root.inOverflow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        iconSource: root.modelData.icon
        label: root.modelData.title || root.modelData.id || "Application"
        dragEnabled: true
        dragSurfaceX: root.surfaceX
        dragSurfaceY: root.surfaceY
        onClicked: mouse => root.activated(root.modelData, mouse.button)
        onHoverEntered: root.hoverEntered(root.modelData)
        onHoverExited: root.hoverExited()
        onDragStarted: (x, y) => root.dragStarted(root.modelData, x, y)
        onDragMoved: (x, y) => root.dragMoved(x, y)
        onDragFinished: (x, y) => root.dragFinished(x, y)
        onDragCanceled: root.dragCanceled()
    }
}
