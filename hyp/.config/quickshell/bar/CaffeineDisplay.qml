import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Read-only Caffeine state for lock surfaces. The interactive component owns
// the idle inhibitor and IPC target, so it must not be instantiated twice.
Item {
    id: root
    property color foreground: Theme.foreground
    property bool on: false
    implicitWidth: icon.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    FileView {
        id: stateFile
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/caffeine.json`
        printErrors: false
        watchChanges: true
        onLoaded: {
            try {
                const state = JSON.parse(text())
                root.on = state.active && (state.until < 0 || state.until > Date.now())
            } catch (error) { root.on = false }
        }
        onFileChanged: reload()
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Theme.yellow, 0.18)
        visible: root.on
    }
    Text {
        id: icon
        anchors.centerIn: parent
        text: ""
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
        color: root.on ? Theme.yellow : Qt.alpha(root.foreground, 0.45)
    }
}
