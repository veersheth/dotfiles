import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.common

// Popup that drops from the bar. Set anchorItem to the bar module and call
// toggle() / close(). Layer-shell surface so Hyprland blur applies.
PanelWindow {
    id: root

    default property alias content: paddedContent.data
    property real contentWidth:  200
    property real contentHeight: 200
    property int  contentPadding: 16
    property bool shown: false
    property Item anchorItem: null
    property double dismissedAt: 0
    property bool grabFocus: true
    property bool dismissOnFocusLoss: true
    // Optional second window (e.g. a context menu) to include in the same
    // focus grab so hover events reach it while the grab is active.
    property var extraGrabWindow: null
    // Set false in a child popup that manages Escape itself (e.g. two-stage).
    property bool handleEscape: true
    // Left-align the popup's left edge with the anchor instead of centering.
    property bool alignLeft: false

    // Scale origin X in card-local px — anchor centre projected onto the card.
    // This makes the popup grow exactly from the button that opened it.
    readonly property real _originX: {
        if (!anchorItem || !screen) return contentWidth / 2;
        const ax = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x - screen.x;
        return Math.max(0, Math.min(contentWidth, Math.round(ax) - WlrLayershell.margins.left));
    }
    readonly property real _originY: BarState.barBottom ? contentHeight : 0

    // Unified scale driven by animations so we only need one NumberAnimation.
    property real _scale: 0

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }

    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:    !BarState.barBottom
    anchors.bottom: BarState.barBottom
    anchors.left:   true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    WlrLayershell.margins.top:    BarState.barBottom ? 0 : Theme.barHeight + 4
    WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight + 4 : 0
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const sx = screen?.x ?? 0;
        const sw = screen?.width ?? 9999;
        if (root.alignLeft) {
            const left = anchorItem.mapToGlobal(0, 0).x;
            return Math.max(0, Math.min(Math.round(left - sx), sw - contentWidth - 2));
        }
        const mid   = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const ideal = Math.round(mid - sx - contentWidth / 2);
        return Math.max(0, Math.min(ideal, sw - contentWidth - 2));
    }

    implicitWidth:  contentWidth  + 2
    implicitHeight: contentHeight + 2

    onShownChanged: {
        if (shown) {
            root._scale = 0
            visible     = true
            enterAnim.restart()
        } else {
            enterAnim.stop()
            exitAnim.restart()
        }
    }

    Rectangle {
        id: card
        x: 0; y: 0
        width:  root.contentWidth
        height: root.contentHeight
        radius: Theme.popupRadius
        opacity: 1

        transform: Scale {
            xScale:   root._scale
            yScale:   root._scale
            origin.x: root._originX
            origin.y: root._originY
        }

        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        Item {
            id: contentItem
            anchors.fill: parent
            Item {
                id: paddedContent
                anchors { fill: parent; margins: root.contentPadding }
            }
        }
    }

    // ── Enter: spring pop — cubic-bezier(0.34, 1.56, 0.64, 1) ───────────
    // The y > 1 control point gives Apple's characteristic micro-overshoot.
    NumberAnimation {
        id: enterAnim
        target: root; property: "_scale"
        to: 1.0; duration: 340
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 1.2, 0.64, 1.0, 1.0, 1.0]
    }

    // ── Exit: fast collapse — cubic-bezier(0.32, 0, 0.67, 0) ────────────
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

    Shortcut {
        sequence: "Escape"
        enabled: root.shown && root.handleEscape
        onActivated: root.close()
    }

    HyprlandFocusGrab {
        windows: root.extraGrabWindow !== null ? [root, root.extraGrabWindow] : [root]
        active: root.shown && root.grabFocus
        onCleared: {
            if (!root.dismissOnFocusLoss) return
            root.dismissedAt = Date.now()
            root.shown = false
        }
    }
}
