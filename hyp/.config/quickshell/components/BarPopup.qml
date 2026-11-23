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
    property bool grabFocus: true
    property bool dismissOnOutsideClick: true
    // Optional second window (e.g. a context menu) to include in the same
    // focus grab so hover events reach it while the grab is active.
    property var extraGrabWindow: null
    // Set false in a child popup that manages Escape itself (e.g. two-stage).
    property bool handleEscape: true
    // Left-align the popup's left edge with the anchor instead of centering.
    property bool alignLeft: false
    property int rightEdgeInset: 2
    readonly property int shadowPadding: 16
    property bool alive: false
    property real dist: -contentHeight
    readonly property int dRest: 4
    Component.onDestruction: BarState.releasePopup(root)

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }
    function closeForReplacement() {
        shown = false
        exitAnim.stop()
        alive = false
    }

    screen: anchorItem?.QsWindow.window?.screen ?? null
    anchors.top:    !BarState.barBottom
    anchors.bottom: BarState.barBottom
    anchors.left:   true
    exclusiveZone: -1
    color: "transparent"
    visible: alive

    Connections {
        target: root
        function onShownChanged() {
            if (root.shown) {
                BarState.activatePopup(root)
                exitAnim.stop()
                if (!root.alive) root.dist = -root.contentHeight
                root.alive = true
                enterAnim.restart()
                Qt.callLater(() => {
                    if (root.shown) card.forceActiveFocus()
                })
            } else {
                BarState.releasePopup(root)
                enterAnim.stop()
                exitAnim.restart()
            }
        }
    }

    BarClickAway {
        screen: root.screen
        visible: root.shown && root.grabFocus && root.dismissOnOutsideClick
            && !Compositor.hyprland
        popupX: root.WlrLayershell.margins.left + root.shadowPadding
        popupY: BarState.barBottom
            ? height - Theme.barHeight - root.dRest - root.contentHeight
            : Theme.barHeight + root.dRest
        popupWidth: root.contentWidth
        popupHeight: root.contentHeight
        onDismissed: {
            root.dismissedAt = Date.now()
            root.close()
        }
    }

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    WlrLayershell.margins.top:    BarState.barBottom ? 0 : Theme.barHeight
    WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight : 0
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
    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

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
        focus: true
        x: root.shadowPadding
        y: BarState.barBottom ? root.height - root.dist - height : root.dist
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

    NumberAnimation {
        id: enterAnim
        target: root; property: "dist"; to: root.dRest
        duration: 460
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    }

    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: root; property: "dist"; to: -root.contentHeight
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.7, 0.0, 0.84, 0.0, 1.0, 1.0]
        }
        ScriptAction { script: root.alive = false }
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
                if (!root.shown || !root.dismissOnOutsideClick) return
                root.dismissedAt = Date.now()
                root.shown = false
            }
        }
    }
}
