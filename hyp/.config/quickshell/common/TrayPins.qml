pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var pinnedIds: []

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/tray-pins.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const ids = JSON.parse(text())
                if (Array.isArray(ids))
                    root.pinnedIds = [...new Set(ids.filter(id => typeof id === "string" && id !== ""))]
            } catch (error) { root.pinnedIds = [] }
        }
    }

    function isPinned(item) {
        return !!item?.id && pinnedIds.includes(item.id)
    }

    function place(id, index) {
        if (!id) return
        const oldIndex = pinnedIds.indexOf(id)
        const ids = pinnedIds.filter(value => value !== id)
        const destination = index > oldIndex && oldIndex >= 0 ? index - 1 : index
        ids.splice(Math.max(0, Math.min(destination, ids.length)), 0, id)
        pinnedIds = ids
        store.setText(JSON.stringify(ids))
    }

    function unpin(id) {
        const ids = pinnedIds.filter(value => value !== id)
        if (ids.length === pinnedIds.length) return
        pinnedIds = ids
        store.setText(JSON.stringify(ids))
    }
}
