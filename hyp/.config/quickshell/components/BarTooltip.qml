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

    // Scale origin: anchor centre projected onto the card (same logic as BarPopup).
    readonly property real _originX: {
        if (!anchorItem || !screen) return contentWidth / 2;
        const ax = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x - screen.x;
        return Math.max(0, Math.min(contentWidth, Math.round(ax) - WlrLayershell.margins.left));
    }
    readonly property real _originY: BarState.barBottom ? contentHeight : 0

    property real _scale: 0

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
    anchors.top:    !BarState.barBottom
    anchors.bottom: BarState.barBottom
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: false
    mask: Region {}

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.margins.top:    BarState.barBottom ? 0 : Theme.barHeight + 4
    WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight + 4 : 0
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
            root._scale = 0
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
        radius: Theme.popupRadius
        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        transform: Scale {
            xScale:   root._scale
            yScale:   root._scale
            origin.x: root._originX
            origin.y: root._originY
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    // ── Enter: spring pop ─────────────────────────────────────────────────
    NumberAnimation {
        id: enterAnim
        target: root; property: "_scale"
        to: 1.0; duration: 340
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 1.2, 0.64, 1.0, 1.0, 1.0]
    }

    // ── Exit: fast collapse ───────────────────────────────────────────────
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: root; property: "_scale"
            to: 0; duration: 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.32, 0.0, 0.67, 0.0, 1.0, 1.0]
        }
        ScriptAction { script: root.visible = false }
    }
}
