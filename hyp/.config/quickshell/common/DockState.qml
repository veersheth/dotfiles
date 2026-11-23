pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Bottom-only dock state. The dock never takes part in the compositor's
// exclusive-zone layout; it either sits above the screen edge or peeks up
// temporarily when that edge is hovered.
Singleton {
    id: root
    property bool dockAutoHide: true
    property bool dockPeek: false
    property bool dockEdgeArmed: true
    property int dockIconSize: 32
    readonly property int minIconSize: 20
    readonly property int maxIconSize: 72

    function setDockAutoHide(v) {
        dockAutoHide = v
        dockPeek = false
        dockEdgeArmed = true
        DockHover.reset()
        store.setText(v ? "true" : "false")
    }

    function toggleDockAutoHide() { setDockAutoHide(!dockAutoHide) }

    function showDockPeek() {
        if (!dockAutoHide || dockPeek) return
        dockPeek = true
        dockEdgeArmed = false
    }

    function triggerEdgePeek() {
        if (!dockEdgeArmed) return
        showDockPeek()
    }

    function rearmEdge() { dockEdgeArmed = true }

    function hideDockPeek() {
        if (!dockAutoHide) return
        dockPeek = false
        dockEdgeArmed = true
        DockHover.reset()
    }

    function setDockIconSize(v) {
        const size = Math.max(root.minIconSize, Math.min(root.maxIconSize, Math.round(v)));
        if (size === root.dockIconSize) return;
        root.dockIconSize = size;
        iconSizeStore.setText(String(size));
    }

    function nudgeIconSize(steps) { setDockIconSize(root.dockIconSize + steps * 2) }
    function scaleIconSize(factor) { setDockIconSize(root.dockIconSize * factor) }

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/dock-autohide.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.dockAutoHide = text().trim() !== "false"
    }

    FileView {
        id: iconSizeStore
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/dock-icon-size.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            const value = Number(text().trim());
            if (value >= root.minIconSize && value <= root.maxIconSize)
                root.dockIconSize = Math.round(value);
        }
    }
}
