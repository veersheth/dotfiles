import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Hover tooltip that drops from the bar under a module. Click-through,
// unfocusable. Call show(item) on hover-enter and hide() on hover-exit.
PanelWindow {
    id: root

    default property alias content: contentItem.data
    property real contentWidth: 120
    property real contentHeight: 32
    property Item anchorItem: null
    property bool shown: false
    // The dock reuses this tooltip above the bottom edge; existing bar modules
    // keep the defaults below.
    property bool anchorToBottom: BarState.barBottom
    property int edgeMargin: Theme.barHeight + 4

    function show(item) {
        anchorItem = item;
        if (shown || visible) shown = true;
        else showDelay.restart();
    }
    function hide() {
        showDelay.stop();
        shown = false;
    }

    onShownChanged: {
        if (shown) {
            card.opacity = 0;
            card.scale = 0.92;
            enterAnim.restart();
        } else {
            enterAnim.stop();
        }
    }

    Timer { id: showDelay; interval: 300; onTriggered: root.shown = true }

    screen: anchorItem?.QsWindow.window?.screen ?? null
    anchors.top:    !root.anchorToBottom
    anchors.bottom: root.anchorToBottom
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: shown
    mask: Region {}

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.margins.top:    root.anchorToBottom ? 0 : root.edgeMargin
    WlrLayershell.margins.bottom: root.anchorToBottom ? root.edgeMargin : 0
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const mid = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx  = screen?.x ?? 0;
        const sw  = screen?.width ?? 9999;
        return Math.max(0, Math.min(Math.round(mid - sx - implicitWidth / 2),
            sw - implicitWidth - 8));
    }

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.popupRadius
        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true
        transformOrigin: root.anchorToBottom ? Item.Bottom : Item.Top

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: card; property: "opacity"
            to: 1; duration: 160; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: card; property: "scale"
            to: 1; duration: 180; easing.type: Easing.OutCubic
        }
    }
}
