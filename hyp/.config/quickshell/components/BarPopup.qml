import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.common

// Popup that leaks from the bar. Set anchorItem to the bar module and call
// toggle() / close(). Layer-shell surface so Hyprland blur applies.
PanelWindow {
    id: root

    default property alias content: card.content
    property real contentWidth: 200
    property real contentHeight: 200
    property bool shown: false
    property Item anchorItem: null
    property double dismissedAt: 0
    property real progress: 0

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }

    // ── layer-shell placement ─────────────────────────────────────────
    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:  true
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
        startWidth: Math.min(root.contentWidth,
            Math.max(40, root.anchorItem?.width ?? root.contentWidth * 0.35))
    }

    NumberAnimation {
        id: enterAnim
        target: root; property: "progress"
        to: 1; duration: 600
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: root; property: "progress"
            to: 0; duration: 260; easing.type: Easing.InCubic
        }
        ScriptAction { script: root.visible = false }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: {
            root.dismissedAt = Date.now();
            root.shown = false;
        }
    }
}
