pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool barBottom: false
    property bool transparent: false
    signal wallpaperPickerRequested()

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-position.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.barBottom = text().trim() === "bottom"
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
