pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property var defaults: ["tray", "caffeine", "wifi", "bluetooth",
        "clock", "volume", "battery", "notifications", "power"]
    property var modules: defaults

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/bar-module-order.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (!Array.isArray(saved)) return
                root.modules = [...new Set(saved.filter(key => root.defaults.includes(key))),
                    ...root.defaults.filter(key => !saved.includes(key))]
            } catch (error) { root.modules = root.defaults }
        }
    }

    function move(key, index) {
        const from = modules.indexOf(key)
        if (from < 0) return
        const reordered = modules.filter(value => value !== key)
        const destination = Math.max(0, Math.min(index - (index > from ? 1 : 0), reordered.length))
        reordered.splice(destination, 0, key)
        if (reordered.every((value, i) => value === modules[i])) return
        modules = reordered
        store.setText(JSON.stringify(reordered))
    }
}
