pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var allTags: []
    property var clients: []

    function parse(line, key) {
        try {
            const data = JSON.parse(line)
            return data[key] ?? []
        } catch (e) {
            console.warn("Mango IPC:", e)
            return []
        }
    }

    function tagsFor(monitor) {
        return allTags.find(m => m.monitor === monitor)?.tags ?? []
    }

    function view(monitor, index) {
        // viewcrossmon targets the bar's monitor even when another is focused.
        Quickshell.execDetached(["mmsg", "dispatch", `viewcrossmon,${index},${monitor}`])
    }

    function focus(id) {
        Quickshell.execDetached(["mmsg", "dispatch", "focusid", `client,${id}`])
    }

    function minimize(id) {
        Quickshell.execDetached(["mmsg", "dispatch", "minimized", `client,${id}`])
    }

    function restore(id) {
        Quickshell.execDetached(["mmsg", "dispatch", "restore_minimized", `client,${id}`])
    }

    Process {
        running: Compositor.mango
        command: ["mmsg", "watch", "all-tags"]
        stdout: SplitParser { onRead: line => root.allTags = root.parse(line, "all_tags") }
    }

    Process {
        running: Compositor.mango
        command: ["mmsg", "watch", "all-clients"]
        stdout: SplitParser { onRead: line => root.clients = root.parse(line, "clients") }
    }
}
