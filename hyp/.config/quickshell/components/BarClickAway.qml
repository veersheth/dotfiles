import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Captures clicks around a bar popup without reacting to pointer movement.
PanelWindow {
    id: root
    property real popupX: 0
    property real popupY: 0
    property real popupWidth: 0
    property real popupHeight: 0
    signal dismissed()

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:popup-dismiss"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        width: root.width
        height: root.height

        Region {
            x: root.popupX
            y: root.popupY
            width: root.popupWidth
            height: root.popupHeight
            intersection: Intersection.Subtract
        }
        Region {
            y: BarState.barBottom ? root.height - Theme.barHeight : 0
            width: root.width
            height: Theme.barHeight
            intersection: Intersection.Subtract
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismissed()
    }
}
