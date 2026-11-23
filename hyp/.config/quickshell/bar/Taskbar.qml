import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.common
import qs.components

Item {
    id: root

    property int slotSize: Theme.barHeight
    property int iconSize: 28
    property int iconPadding: 0
    property int separatorWidth: 12
    property real separatorHeightRatio: 0.9
    property int hoverRadius: Theme.itemRadius
    property int itemSpacing: 6
    property string monitorName: ""
    property var hoverTracker: BarHover
    property string hoverOwner: ""
    property bool trackHover: true
    property bool pinnedMode: false
    property bool showTooltips: false
    property int tooltipEdgeMargin: Theme.barHeight + 4
    property bool monochromeInactive: true
    property real inactiveOpacity: 0.75

    property string dragKey: ""
    property string dragAppId: ""
    property real dragScreenX: 0
    property real dragScreenY: 0
    property real markerX: 0
    property int markerIndex: 0

    implicitHeight: root.slotSize + root.iconPadding * 2
    implicitWidth: listView.contentWidth
    readonly property int windowCount: taskModel.count
    readonly property int pinnedCount: {
        let count = 0;
        for (let i = 0; i < taskModel.count; i++)
            if (taskModel.get(i).pinned) count++;
        return count;
    }
    readonly property int activeIndex: {
        const tops = visibleTops();
        for (let i = 0; i < taskModel.count; i++) {
            const entry = taskModel.get(i);
            if (entry.pinned) {
                if (tops.some(t => AppIcons.canonicalId(root.appIdOf(t)) === entry.key
                        && (Compositor.mango ? t.is_focused : t.activated)))
                    return i;
                continue;
            }
            const top = tops.find(t => (Compositor.mango ? String(t.id) : t.address) === entry.address);
            if (!top) continue;
            if (Compositor.mango ? (top.is_focused ?? false) : (top.activated ?? false))
                return i;
        }
        return -1;
    }

    // Snapshot re-evaluates whenever toplevels are added/removed, change
    // workspace, or move between monitors. Drives syncModel() so the ListModel
    // stays in sorted order with per-item signals.
    readonly property var snapshot: {
        const tops = visibleTops();
        return Compositor.mango
            ? tops.map(t => String(t.id) + ":" + (t.tags?.[0] ?? 999) + ":" + t.is_focused + ":" + (t.monitor ?? ""))
            : tops.map(t => t.address + ":" + (t.workspace?.id ?? 999) + ":" + monitorKey(t));
    }
    onSnapshotChanged: syncModel()
    onMonitorNameChanged: syncModel()

    ListModel { id: taskModel }
    Component.onCompleted: syncModel()

    Connections {
        target: DockPins
        function onPinsChanged() { if (root.pinnedMode) syncModel() }
    }

    function monitorKey(t) {
        if (Compositor.mango) return t.monitor ?? "";
        const m = t.monitor;
        if (m && typeof m === "object") return m.name ?? m.output ?? m.description ?? "";
        return m ?? "";
    }

    function visibleTops() {
        const tops = Compositor.mango ? Mango.clients : Hyprland.toplevels.values;
        if (root.monitorName === "") return tops;
        return tops.filter(t => {
            const name = monitorKey(t);
            return name === "" || name === root.monitorName;
        });
    }

    function appIdOf(t) {
        if (!t) return "";
        return Compositor.mango
            ? (t.appid ?? "")
            : (t.wayland?.appId ?? t.lastIpcObject?.class ?? "");
    }

    function windowKey(t) {
        return Compositor.mango ? String(t.id) : t.address;
    }

    function windowsFor(key) {
        return visibleTops().filter(t => AppIcons.canonicalId(root.appIdOf(t)) === key);
    }

    function focusWindow(t) {
        if (!t) return;
        if (Compositor.mango) Mango.focus(Number(root.windowKey(t)));
        else t.wayland?.activate();
    }

    function minimizeWindow(t) {
        if (!t) return;
        if (Compositor.mango) Mango.minimize(Number(root.windowKey(t)));
        else t.wayland?.setMinimized(true);
    }

    function restoreWindow(t) {
        if (!t) return;
        if (Compositor.mango) Mango.restore(Number(root.windowKey(t)));
        else {
            t.wayland?.setMinimized(false);
            t.wayland?.activate();
        }
    }

    function launchDesktop(id) {
        if (String(id ?? "") !== "")
            Quickshell.execDetached(["gtk-launch", String(id)]);
    }

    function applyModel(entries) {
        // Reconcile in place instead of clear(): the dock watches windowCount
        // and would interpret a momentary 0 as "all windows closed", tucking
        // itself away on every focus change.
        for (let i = 0; i < entries.length; i++) {
            if (i < taskModel.count) taskModel.set(i, entries[i]);
            else taskModel.append(entries[i]);
        }
        for (let i = taskModel.count - 1; i >= entries.length; i--)
            taskModel.remove(i);
    }

    function syncModel() {
        const entries = [];

        if (!root.pinnedMode) {
            const tops = visibleTops()
                .slice()
                .sort((a, b) => Compositor.mango
                    ? (a.tags?.[0] ?? 999) - (b.tags?.[0] ?? 999)
                    : (a.workspace?.id ?? 999) - (b.workspace?.id ?? 999));
            for (const top of tops) {
                const appId = root.appIdOf(top);
                entries.push({
                    address: root.windowKey(top),
                    key: AppIcons.canonicalId(appId),
                    pinned: false,
                    separator: false,
                    name: top.title ?? AppIcons.displayName(appId),
                    desktopId: appId
                });
            }
            applyModel(entries);
            return;
        }

        // Pinned launchers first, in their saved order.
        for (const pin of DockPins.pins) {
            entries.push({
                address: "pin:" + pin.key,
                key: pin.key,
                pinned: true,
                separator: false,
                name: pin.name,
                desktopId: pin.desktopId
            });
        }

        const unpinned = visibleTops().filter(top => {
            const appId = root.appIdOf(top);
            return appId !== ""
                && !DockPins.isPinned(AppIcons.canonicalId(appId));
        });

        // A real slot in the layout, so the breathing room around the line is
        // actual space rather than invisible padding over the card background.
        if (entries.length > 0 && unpinned.length > 0) {
            entries.push({
                address: "", key: "", pinned: false, separator: true,
                name: "", desktopId: ""
            });
        }

        // Every unpinned open window appends to the right in arrival order.
        for (const top of unpinned) {
            const appId = root.appIdOf(top);
            const key = AppIcons.canonicalId(appId);
            entries.push({
                address: root.windowKey(top),
                key: key,
                pinned: false,
                separator: false,
                name: top.title ?? AppIcons.displayName(appId),
                desktopId: appId
            });
        }

        applyModel(entries);
    }

    function iconPathFor(appId) { return AppIcons.iconPath(appId) }

    function beginDrag(key, appId, x, y) {
        dragKey = key
        dragAppId = appId
        dragScreenX = x
        dragScreenY = y
        updateDrag(x, y)
    }

    function updateDrag(x, y) {
        if (dragKey === "") return
        dragScreenX = x
        dragScreenY = y
        const screen = root.QsWindow.window?.screen
        const originX = (screen?.x ?? 0) + root.mapToItem(null, 0, 0).x
        const cell = root.slotSize + root.iconPadding * 2 + root.itemSpacing
        const local = x - originX
        markerIndex = Math.max(0, Math.min(DockPins.pins.length,
            Math.round((local - root.iconPadding) / cell)))
        markerX = markerIndex * cell
    }

    function finishDrag(x, y) {
        if (dragKey === "") return
        updateDrag(x, y)
        const key = dragKey
        dragKey = ""
        dragAppId = ""
        DockPins.place(key, markerIndex)
    }

    function cancelDrag() {
        dragKey = ""
        dragAppId = ""
    }

    function iconForApp(appId) {
        const id = (appId ?? "").toLowerCase();
        if (id.includes("firefox"))                            return "";
        if (id.includes("chrome") || id.includes("chromium")) return "";
        if (id.includes("kitty"))                              return "";
        if (id.includes("alacritty"))                          return "";
        if (id.includes("ghostty"))                            return "";
        if (id.includes("code") || id.includes("vscode") || id.includes("cursor")) return "󰨞";
        if (id.includes("nvim") || id.includes("neovim"))      return "";
        if (id.includes("nautilus") || id.includes("files"))   return "";
        if (id.includes("spotify"))                            return "";
        if (id.includes("discord"))                            return "󰙯";
        if (id.includes("telegram"))                           return "";
        if (id.includes("slack"))                              return "";
        if (id.includes("obsidian"))                           return "";
        if (id.includes("mpv"))                                return "";
        if (id.includes("vlc"))                                return "󰕼";
        if (id.includes("steam"))                              return "";
        if (id.includes("thunar"))                             return "󰝰";
        if (id.includes("blender"))                            return "󰂫";
        return "󰣆";
    }

    Rectangle {
        id: dropMarker
        z: 2
        visible: root.dragKey !== "" && root.pinnedMode
        x: root.markerX
        y: 0
        width: root.slotSize + root.iconPadding * 2
        height: root.slotSize + root.iconPadding * 2
        radius: root.hoverRadius
        color: "transparent"
        border.color: Theme.blue
        border.width: 1

        Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }

    ListView {
        id: listView
        anchors.centerIn: parent
        orientation: ListView.Horizontal
        spacing: root.itemSpacing
        width: contentWidth
        height: root.slotSize + root.iconPadding * 2
        model: taskModel
        clip: false
        interactive: false   // never let a drag become a list flick

        populate: Transition {}

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "y"; from: root.slotSize / 2; to: 0; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
                NumberAnimation { property: "y"; to: root.slotSize / 2; duration: 220; easing.type: Easing.InCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: dlg
            required property int index
            required property string address
            required property string key
            required property bool pinned
            required property bool separator
            required property string name
            required property string desktopId

            readonly property var windows: dlg.pinned ? root.windowsFor(dlg.key) : []
            readonly property var toplevel: dlg.pinned
                ? (windows.find(t => Compositor.mango ? t.is_focused : t.activated) ?? windows[0] ?? null)
                : (visibleTops().find(t => (Compositor.mango ? String(t.id) : t.address) === dlg.address) ?? null)
            readonly property string appId: dlg.pinned
                ? dlg.key
                : (Compositor.mango ? (dlg.toplevel?.appid ?? "")
                    : (dlg.toplevel?.wayland?.appId ?? dlg.toplevel?.lastIpcObject?.class ?? ""))
            readonly property bool active: dlg.pinned
                ? windows.some(t => Compositor.mango ? t.is_focused : t.activated)
                : (Compositor.mango ? (dlg.toplevel?.is_focused ?? false)
                    : (dlg.toplevel?.activated ?? false))
            readonly property bool minimized: dlg.pinned
                ? (windows.length > 0 && windows.every(t => Compositor.mango
                    ? (t.is_minimized ?? false) : (t.wayland?.minimized ?? false)))
                : (Compositor.mango ? (dlg.toplevel?.is_minimized ?? false)
                    : (dlg.toplevel?.wayland?.minimized ?? false))
            readonly property string title: dlg.toplevel?.title ?? dlg.name
            readonly property string iconSrc: root.iconPathFor(dlg.pinned ? dlg.key : dlg.appId)

            width: dlg.separator
                ? root.separatorWidth
                : root.slotSize + root.iconPadding * 2
            height: root.slotSize + root.iconPadding * 2
            opacity: dlg.minimized ? 0.3 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            // Dedicated divider entry: no icon, no tooltip, no click target.
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: root.iconSize * root.separatorHeightRatio
                color: Theme.border
                visible: dlg.separator
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: root.iconSize
                source: dlg.iconSrc
                visible: !dlg.separator && dlg.iconSrc !== ""
                opacity: dlg.active ? 1.0 : root.inactiveOpacity
                Behavior on opacity { NumberAnimation { duration: 150 } }

                layer.enabled: root.monochromeInactive && !dlg.active
                layer.effect: MultiEffect {
                    saturation: root.monochromeInactive && !dlg.active ? -1.0 : 0.0
                    Behavior on saturation { NumberAnimation { duration: 150 } }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !dlg.separator && dlg.iconSrc === ""
                text: root.iconForApp(dlg.appId)
                font.family: Theme.nerdFont
                font.pixelSize: Math.max(14, root.iconSize - 8)
                color: dlg.active ? Theme.blue : Qt.alpha(Theme.foreground, 0.6)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            BarTooltip {
                id: tip
                anchorItem: dlg
                anchorToBottom: true
                edgeMargin: root.tooltipEdgeMargin
                contentWidth: Math.min(300, tipText.implicitWidth + 24)
                contentHeight: tipText.implicitHeight + 14

                Text {
                    id: tipText
                    anchors.centerIn: parent
                    width: Math.min(276, implicitWidth)
                    text: dlg.title !== "" ? dlg.title : (dlg.name || dlg.appId)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Font.Medium
                    color: Theme.foreground
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mo
                anchors.fill: parent
                enabled: !dlg.separator
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                property real pressX: 0
                property real pressY: 0
                property bool dragging: false
                property bool suppressClick: false

                onEntered: {
                    if (dlg.separator) return;
                    if (root.trackHover) root.hoverTracker.enter(root.hoverOwner)
                    if (root.showTooltips) tip.show(dlg)
                }
                onExited: {
                    if (root.trackHover) root.hoverTracker.leave(root.hoverOwner)
                    tip.hide()
                }
                onPressed: mouse => {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    dragging = false;
                    if (mouse.button === Qt.RightButton) {
                        tip.hide();
                        if (dlg.pinned) DockPins.unpin(dlg.key);
                        else DockPins.pin(dlg.appId, dlg.title || dlg.name, dlg.desktopId);
                        mouse.accepted = true;
                    }
                }
                onPositionChanged: mouse => {
                    if (!(mouse.buttons & Qt.LeftButton) || !dlg.pinned) return;
                    if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) < 8) return;
                    const scene = mo.mapToItem(null, mouse.x, mouse.y);
                    const screen = root.QsWindow.window?.screen;
                    const sx = (screen?.x ?? 0) + scene.x;
                    const sy = (screen?.y ?? 0) + scene.y;
                    if (!dragging) {
                        dragging = true;
                        suppressClick = true;
                        tip.hide();
                        root.beginDrag(dlg.key, dlg.appId, sx, sy);
                    }
                    root.updateDrag(sx, sy);
                }
                onReleased: mouse => {
                    if (!dragging) return;
                    const scene = mo.mapToItem(null, mouse.x, mouse.y);
                    const screen = root.QsWindow.window?.screen;
                    dragging = false;
                    root.finishDrag((screen?.x ?? 0) + scene.x, (screen?.y ?? 0) + scene.y);
                }
                onCanceled: {
                    const wasDragging = dragging;
                    dragging = false;
                    if (wasDragging) root.cancelDrag();
                }
                onClicked: mouse => {
                    if (dlg.separator || mouse.button !== Qt.LeftButton || dragging) return;
                    if (suppressClick) { suppressClick = false; return; }
                    tip.hide();
                    if (dlg.pinned && dlg.toplevel === null) {
                        root.launchDesktop(dlg.desktopId);
                        return;
                    }
                    if (dlg.pinned) {
                        root.focusWindow(dlg.toplevel);
                        return;
                    }
                    if (Compositor.mango) {
                        if (dlg.active) Mango.minimize(Number(dlg.address));
                        else if (dlg.minimized) Mango.restore(Number(dlg.address));
                        else Mango.focus(Number(dlg.address));
                        return;
                    }
                    if (dlg.active) {
                        dlg.toplevel?.wayland?.setMinimized(true);
                    } else {
                        if (dlg.minimized) dlg.toplevel?.wayland?.setMinimized(false);
                        dlg.toplevel?.wayland?.activate();
                    }
                }
            }
        }
    }
}
