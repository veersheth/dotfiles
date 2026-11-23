pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool barBottom: false
    property bool transparent: false
    property bool exposeActive: false
    property bool exposeGestureTracking: false
    property real exposeGestureProgress: 0
    // Auto-hide is a mode: the bar never reserves space while it is on, and
    // edge hover only peeks at it temporarily.
    property bool barAutoHide: false
    property bool barPeek: false
    property double peekAt: 0
    property bool edgeArmed: true
    property bool rearrangeModules: false
    property var activePopup: null
    signal wallpaperPickerRequested()
    signal colorPickerRequested()
    signal popupActivated(var popup)

    function activatePopup(popup) {
        if (activePopup && activePopup !== popup) {
            if (activePopup.closeForReplacement)
                activePopup.closeForReplacement()
            else
                activePopup.close()
        }
        activePopup = popup
        popupActivated(popup)
    }

    function releasePopup(popup) {
        if (activePopup === popup) activePopup = null
    }

    function setBarAutoHide(v) {
        if (activePopup) activePopup.close()
        barAutoHide = v
        barPeek = false
        edgeArmed = true
        BarHover.reset()
        autoHideStore.setText(v ? "true" : "false")
    }

    function toggleBarAutoHide() { setBarAutoHide(!barAutoHide) }

    function setRearrangeModules(v) {
        rearrangeModules = v
        if (v) barPeek = true
    }

    function toggleRearrangeModules() { setRearrangeModules(!rearrangeModules) }

    function requestWallpaperPicker() { wallpaperPickerRequested() }
    function requestColorPicker() { colorPickerRequested() }

    function showBarPeek() {
        if (!barAutoHide || barPeek) return
        peekAt = Date.now()
        barPeek = true
        edgeArmed = false
    }

    function triggerEdgePeek() {
        if (!edgeArmed) return
        showBarPeek()
    }

    function rearmEdge() { edgeArmed = true }

    function hideBarPeek() {
        if (!barAutoHide) return
        barPeek = false
        edgeArmed = true
        BarHover.reset()
    }

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-position.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.barBottom = text().trim() === "bottom"
    }

    FileView {
        id: autoHideStore
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-autohide.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.barAutoHide = text().trim() === "true"
    }

    FileView {
        id: appearanceStore
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-transparent.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.transparent = text().trim() === "true"
    }

    function setTransparent(v) {
        transparent = v;
        appearanceStore.setText(v ? "true" : "false");
    }

    function setBottom(v) {
        barBottom = v;
        store.setText(v ? "bottom" : "top");
    }
}
