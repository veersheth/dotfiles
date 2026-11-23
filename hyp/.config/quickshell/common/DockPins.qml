pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Persisted dock launchers. Order in this list is the dock order; running
// windows for pinned apps share one icon, and unpinned windows append right.
Singleton {
    id: root
    property var pins: []

    function keyFor(appId) { return AppIcons.canonicalId(appId) }

    function entry(key) {
        return pins.find(pin => pin.key === key) ?? null;
    }

    function isPinned(appId) {
        const key = root.keyFor(appId);
        return key !== "" && entry(key) !== null;
    }

    function pin(appId, name, desktopId) {
        const key = root.keyFor(appId);
        if (key === "" || entry(key)) return;
        const next = pins.concat([{
            key: key,
            name: name || AppIcons.displayName(appId),
            desktopId: AppIcons.desktopId(desktopId || appId || key)
        }]);
        pins = next;
        store.setText(JSON.stringify(next));
    }

    function place(key, index) {
        const oldIndex = pins.findIndex(pin => pin.key === key);
        if (oldIndex < 0) return;
        const list = pins.filter(pin => pin.key !== key);
        const destination = index > oldIndex ? index - 1 : index;
        list.splice(Math.max(0, Math.min(destination, list.length)), 0, pins[oldIndex]);
        pins = list;
        store.setText(JSON.stringify(list));
    }

    function unpin(appId) {
        const key = root.keyFor(appId);
        const list = pins.filter(pin => pin.key !== key);
        if (list.length === pins.length) return;
        pins = list;
        store.setText(JSON.stringify(list));
    }

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/dock-pins.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!Array.isArray(data)) return;
                const cleaned = data
                    .filter(pin => pin && typeof pin.key === "string" && pin.key !== "")
                    .map(pin => ({
                        key: pin.key,
                        name: typeof pin.name === "string" && pin.name !== ""
                            ? pin.name : AppIcons.displayName(pin.key),
                        desktopId: AppIcons.desktopId(
                            typeof pin.desktopId === "string" && pin.desktopId !== ""
                                ? pin.desktopId : pin.key)
                    }));
                const keys = [];
                root.pins = cleaned.filter(pin => {
                    if (keys.indexOf(pin.key) !== -1) return false;
                    keys.push(pin.key);
                    return true;
                });
            } catch (error) { root.pins = [] }
        }
    }
}
