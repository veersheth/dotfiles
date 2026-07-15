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

    function show(item) {
        anchorItem = item;
        if (shown || visible) shown = true;
        else showDelay.restart();
    }
    function hide() {
        showDelay.stop();
        shown = false;
    }

    Timer { id: showDelay; interval: 300; onTriggered: root.shown = true }

    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:  true
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: false
    mask: Region {}

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.margins.top:  Theme.barHeight + 4
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const mid = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx  = screen?.x ?? 0;
        return Math.max(0, Math.round(mid - sx - implicitWidth / 2));
    }

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    onShownChanged: {
        if (shown) {
            exitAnim.stop()
            card.opacity = 0
            visible = true
            enterAnim.restart()
        } else {
            enterAnim.stop()
            exitAnim.restart()
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    NumberAnimation {
        id: enterAnim
        target: card; property: "opacity"
        from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: card; property: "opacity"
            to: 0; duration: 100; easing.type: Easing.InCubic
        }
        ScriptAction { script: root.visible = false }
    }
}
