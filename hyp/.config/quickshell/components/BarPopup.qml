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

    // Seed pill the morph expands from / collapses into
    readonly property real _pillW: 96
    readonly property real _pillH: Theme.pillHeight
    // y the card rests at before opening (bottom bar: near bottom of window)
    readonly property real _cardStartY: BarState.barBottom ? root.contentHeight - root._pillH : 0

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }

    // ── Runtime morph on content resize ───────────────────────────────
    // When dimensions change while the popup is stable, spring the card
    // to the new size with the same liquid feel as the open animation.
    onContentWidthChanged: {
        if (shown && !enterAnim.running && !exitAnim.running) {
            morphW.to = contentWidth; morphW.restart()
        }
    }
    onContentHeightChanged: {
        if (shown && !enterAnim.running && !exitAnim.running) {
            morphH.to = contentHeight; morphH.restart()
        }
    }

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
        const mid  = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx   = screen?.x ?? 0;
        const sw   = screen?.width ?? 9999;
        const ideal = Math.round(mid - sx - contentWidth / 2);
        // clamp so the popup never bleeds past the right screen edge (+2 for border surface)
        return Math.max(0, Math.min(ideal, sw - contentWidth - 2));
    }

    // +2 on each axis so border antialiased edges are never flush with the
    // window boundary (compositor clips the very edge, hiding the border).
    implicitWidth:  contentWidth  + 2
    implicitHeight: contentHeight + 2

    onShownChanged: {
        if (shown) {
            exitAnim.stop()
            morphW.stop(); morphH.stop()
            // Snap card to seed pill and make window visible
            card.x      = (root.contentWidth  - root._pillW) / 2
            card.y      = root._cardStartY
            card.width  = root._pillW
            card.height = root._pillH
            card.radius = root._pillH / 2
            contentItem.opacity = 0
            visible = true
            enterTimer.restart()
        } else {
            enterTimer.stop()
            enterAnim.stop()
            morphW.stop(); morphH.stop()
            exitAnim.restart()
        }
    }

    Timer {
        id: enterTimer
        interval: 0
        onTriggered: {
            // Re-snap pill — layout may have settled during the event-loop tick
            card.x      = (root.contentWidth  - root._pillW) / 2
            card.y      = root._cardStartY
            card.width  = root._pillW
            card.height = root._pillH
            card.radius = root._pillH / 2
            enterAnim.restart()
        }
    }

    Rectangle {
        id: card

        x: 0; y: 0
        width: root.contentWidth
        height: root.contentHeight
        radius: Theme.popupRadius

        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        Item {
            id: contentItem
            anchors.fill: parent
            opacity: 0
            Item {
                id: paddedContent
                anchors { fill: parent; margins: root.contentPadding }
            }
        }
    }

    // ── Runtime springs ────────────────────────────────────────────────
    SpringAnimation { id: morphW; target: card; property: "width";  spring: 8.0; damping: 0.44; epsilon: 0.4 }
    SpringAnimation { id: morphH; target: card; property: "height"; spring: 6.0; damping: 0.40; epsilon: 0.4 }

    // ── Enter: pill → full (liquid blob physics) ───────────────────────
    // Width and x expand faster and bounce back once. Height is softer and
    // lags behind with more overshoot, so the shape momentarily goes wider
    // than it is tall before settling — a fluid blob bloom. Radius also
    // springs past the target (momentarily rounder) then settles.
    ParallelAnimation {
        id: enterAnim
        SpringAnimation { target: card; property: "x";      to: 0;                  spring: 8.0; damping: 0.44; epsilon: 0.4 }
        SpringAnimation { target: card; property: "y";      to: 0;                  spring: 6.0; damping: 0.40; epsilon: 0.4 }
        SpringAnimation { target: card; property: "width";  to: root.contentWidth;  spring: 8.0; damping: 0.44; epsilon: 0.4 }
        SpringAnimation { target: card; property: "height"; to: root.contentHeight; spring: 6.0; damping: 0.40; epsilon: 0.4 }
        SpringAnimation { target: card; property: "radius"; to: Theme.popupRadius;  spring: 4.0; damping: 0.50; epsilon: 0.1 }
        // Content fades in after the card shape is clearly established
        SequentialAnimation {
            PauseAnimation  { duration: 80 }
            NumberAnimation { target: contentItem; property: "opacity"; to: 1; duration: 120; easing.type: Easing.OutCubic }
        }
        onFinished: {
            // Sync if content dimensions changed during the spring
            if (Math.abs(card.width  - root.contentWidth)  > 0.5) { morphW.to = root.contentWidth;  morphW.restart() }
            if (Math.abs(card.height - root.contentHeight) > 0.5) { morphH.to = root.contentHeight; morphH.restart() }
        }
    }

    // ── Exit: full → pill → gone (fast, snappy) ───────────────────────
    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation { target: contentItem; property: "opacity"; to: 0;                              duration: 40;  easing.type: Easing.InCubic }
            NumberAnimation { target: card; property: "x";      to: (root.contentWidth - root._pillW) / 2; duration: 130; easing.type: Easing.InBack; easing.overshoot: 0.35 }
            NumberAnimation { target: card; property: "y";      to: root._cardStartY;                      duration: 120; easing.type: Easing.InBack; easing.overshoot: 0.35 }
            NumberAnimation { target: card; property: "width";  to: root._pillW;                           duration: 130; easing.type: Easing.InBack; easing.overshoot: 0.35 }
            NumberAnimation { target: card; property: "height"; to: root._pillH;                           duration: 120; easing.type: Easing.InBack; easing.overshoot: 0.35 }
            NumberAnimation { target: card; property: "radius"; to: root._pillH / 2;                       duration: 100; easing.type: Easing.InCubic }
        }
        PauseAnimation  { duration: 20 }
        ScriptAction    { script: root.visible = false }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
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
