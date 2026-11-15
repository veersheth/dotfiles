import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
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
    property bool focusAcquired: false
    property bool grabFocus: true
    property bool dismissOnFocusLoss: true
    // Optional second window (e.g. a context menu) to include in the same
    // focus grab so hover events reach it while the grab is active.
    property var extraGrabWindow: null
    // Set false in a child popup that manages Escape itself (e.g. two-stage).
    property bool handleEscape: true
    // Left-align the popup's left edge with the anchor instead of centering.
    property bool alignLeft: false
    property int rightEdgeInset: 2
    readonly property int shadowPadding: 16
    Component.onDestruction: BarState.releasePopup(root)

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
    visible: shown

    onShownChanged: {
        if (shown) {
            BarState.activatePopup(root)
            focusAcquired = false
        } else {
            BarState.releasePopup(root)
            focusCheck.stop()
        }
    }

    Connections {
        target: card.Window.window
        function onActiveChanged() {
            if (Compositor.hyprland || !root.shown) return
            if (card.Window.window?.active) {
                root.focusAcquired = true
                focusCheck.stop()
            } else if (root.focusAcquired) {
                focusCheck.restart()
            }
        }
    }

    Timer {
        id: focusCheck
        interval: 250
        onTriggered: {
            if (root.shown && root.focusAcquired && root.grabFocus
                    && root.dismissOnFocusLoss && !card.Window.window?.active) {
                root.dismissedAt = Date.now()
                root.shown = false
            }
        }
    }

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    WlrLayershell.margins.top:    BarState.barBottom ? 0 : Theme.barHeight + 4
    WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight + 4 : 0
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const sx = screen?.x ?? 0;
        const sw = screen?.width ?? 9999;
        const maxLeft = Math.max(0, sw - contentWidth - shadowPadding * 2);
        if (root.alignLeft) {
            const left = anchorItem.mapToGlobal(0, 0).x;
            return Math.max(0, Math.min(Math.round(left - sx) - shadowPadding, maxLeft));
        }
        const mid   = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const ideal = Math.round(mid - sx - contentWidth / 2);
        return Math.max(0, Math.min(ideal - shadowPadding,
            maxLeft - Math.max(0, rightEdgeInset - shadowPadding)));
    }

    implicitWidth:  contentWidth + shadowPadding * 2
    // Keep the Wayland buffer height stable as list rows change. Resizing the
    // native window requires compositor negotiation and can hitch independently
    // of QML animations. Only the card paints and accepts input in this surface.
    implicitHeight: Math.max(1, (screen?.height ?? 1080) - Theme.barHeight - 8)
    mask: Region { x: card.x; y: card.y; width: card.width; height: card.height }

    RectangularShadow {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
        radius: Theme.popupRadius
        blur: 14
        offset.y: BarState.barBottom ? -3 : 3
        color: "#80000000"
    }

    Rectangle {
        id: card
        x: root.shadowPadding
        y: BarState.barBottom ? root.height - height : 0
        width: root.contentWidth
        height: root.contentHeight
        radius: Theme.popupRadius

        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        Item {
            id: contentItem
            width: root.contentWidth
            height: root.contentHeight
            Item {
                id: paddedContent
                anchors { fill: parent; margins: root.contentPadding }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown && root.handleEscape
        onActivated: root.close()
    }

    Loader {
        active: Compositor.hyprland
        sourceComponent: HyprlandFocusGrab {
            windows: root.extraGrabWindow !== null ? [root, root.extraGrabWindow] : [root]
            active: root.shown && root.grabFocus
            onCleared: {
                if (!root.dismissOnFocusLoss) return
                root.dismissedAt = Date.now()
                root.shown = false
            }
        }
    }
}
