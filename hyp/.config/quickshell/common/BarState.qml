pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool barBottom: false
    signal wallpaperPickerRequested()

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-position.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: root.barBottom = text().trim() === "bottom"
    }

    function setBottom(v) {
        barBottom = v;
        store.setText(v ? "bottom" : "top");
    }
}
