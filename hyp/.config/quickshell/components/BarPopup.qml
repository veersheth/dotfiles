import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.common

// Popup that drops from the bar. Set anchorItem to the bar module and call
// toggle() / close(). Layer-shell surface so Hyprland blur applies.
PanelWindow {
    id: root

    default property alias content: contentItem.data
    property real contentWidth: 200
    property real contentHeight: 200
    property bool shown: false
    property Item anchorItem: null
    property double dismissedAt: 0
    property bool grabFocus: true
    property bool dismissOnFocusLoss: true
    // Optional second window (e.g. a context menu) to include in the same
    // focus grab so hover events reach it while the grab is active.
    property var extraGrabWindow: null

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }

    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:  true
    anchors.left: true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    WlrLayershell.margins.top:  Theme.barHeight + 4
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const track = anchorItem.x;
        const mid   = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx    = screen?.x ?? 0;
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
        radius: 14
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
        from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: card; property: "opacity"
            to: 0; duration: 120; easing.type: Easing.InCubic
        }
        ScriptAction { script: root.visible = false }
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
