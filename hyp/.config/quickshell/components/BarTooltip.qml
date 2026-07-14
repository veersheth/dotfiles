import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Hover tooltip that leaks from the bar under a module — same card language
// as BarPopup, but click-through, unfocusable and quick. Call show(item) on
// hover-enter and hide() on hover-exit.
PanelWindow {
    id: root

    default property alias content: card.content
    property real contentWidth: 120
    property real contentHeight: 32
    property Item anchorItem: null
    property real progress: 0
    property bool shown: false

    // hover-intent delay on first appearance; hopping anchors is instant
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

    // ── layer-shell placement ─────────────────────────────────────────
    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:  true
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: false
    // pure display — never takes input
    mask: Region {}

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.margins.top:  Theme.barHeight - card.overlap
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const mid = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx  = screen?.x ?? 0;
        return Math.max(0, Math.round(mid - sx - implicitWidth / 2));
    }

    implicitWidth:  contentWidth  + card.flare * 2
    implicitHeight: contentHeight + card.overlap

    onShownChanged: {
        if (shown) {
            exitAnim.stop();
            visible = true;
            enterAnim.restart();
        } else {
            enterAnim.stop();
            exitAnim.restart();
        }
    }

    LeakCard {
        id: card
        anchors.fill: parent
        contentWidth:  root.contentWidth
        contentHeight: root.contentHeight
        progress:      root.progress
        flare:         12
        startWidth: Math.min(root.contentWidth,
            Math.max(36, root.anchorItem?.width ?? 40))
    }

    NumberAnimation {
        id: enterAnim
        target: root; property: "progress"
        to: 1; duration: 240
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: root; property: "progress"
            to: 0; duration: 140; easing.type: Easing.InCubic
        }
        ScriptAction { script: root.visible = false }
    }
}
