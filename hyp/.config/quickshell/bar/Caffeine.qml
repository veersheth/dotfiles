import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Caffeine toggle. Click → duration picker popup. State persists across
// quickshell reloads via ~/.local/state/quickshell/caffeine.json.
Item {
    id: root

    property bool on: false
    property real until: -1   // expiry ms timestamp; -1 = indefinite

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: icon.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    // ── Drag-to-set state ─────────────────────────────────────────────
    property bool _dragging: false
    property real _dragMs:   0
    property real _cursorScreenY: 0

    function _dragToMs(dy) {
        if (dy >= 120) return 0;  // 0 = indefinite
        return Math.round(dy / 5) * 5 * 60000;  // 1px = 1 min, snap to 5 min
    }
    function _formatMs(ms) {
        if (ms <= 0) return "Indefinitely";
        const mins = Math.round(ms / 60000);
        if (mins < 60) return `${mins} min`;
        const h = Math.floor(mins / 60), m = mins % 60;
        return m > 0 ? `${h} h ${m} min` : `${h} h`;
    }

    // ── Remaining-time label (ticks every minute while active) ─────────
    property bool _tick: false
    readonly property string remaining: {
        const _ = _tick;
        if (!on || until < 0) return "Indefinitely";
        const mins = Math.max(0, Math.round((until - Date.now()) / 60000));
        if (mins === 0) return "< 1 min";
        if (mins < 60)  return `${mins} min`;
        const h = Math.floor(mins / 60), m = mins % 60;
        return m > 0 ? `${h} h ${m} min` : `${h} h`;
    }
    Timer { interval: 60000; repeat: true; running: root.on && root.until > 0
            onTriggered: root._tick = !root._tick }

    // ── Persistence ────────────────────────────────────────────────────
    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/caffeine.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const s = JSON.parse(text());
                if (s.active && (s.until < 0 || s.until > Date.now())) {
                    root.until = s.until ?? -1;
                    root.on    = true;
                    inhibitProc.running = true;
                    if (root.until > 0) {
                        expiryTimer.interval = Math.max(1000, root.until - Date.now());
                        expiryTimer.restart();
                    }
                }
            } catch(e) {}
        }
    }

    function save() {
        store.setText(JSON.stringify({ active: on, until: until }));
    }

    function activate(durationMs) {
        until = durationMs > 0 ? Date.now() + durationMs : -1;
        on    = true;
        inhibitProc.running = true;
        save();
        picker.close();
        tip.hide();
        if (until > 0) {
            expiryTimer.interval = Math.max(1000, until - Date.now());
            expiryTimer.restart();
        } else {
            expiryTimer.stop();
        }
    }

    function deactivate() {
        on    = false;
        until = -1;
        expiryTimer.stop();
        inhibitProc.running = false;
        save();
        picker.close();
    }

    // Systemd idle inhibitor: keeps hypridle alive (so loginctl lock-session
    // still works) but pauses its idle timers for as long as this process runs.
    // Setting running=false terminates it and releases the inhibitor.
    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell",
                  "--why=caffeinated", "sleep", "infinity"]
    }

    Timer { id: expiryTimer; repeat: false; onTriggered: root.deactivate() }

    // ── Visuals ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: root.on ? Qt.alpha(Theme.yellow, 0.18) : Theme.hover
        opacity: root.on || hitArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on color   { ColorAnimation  { duration: Theme.animDuration } }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: ""
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
        color: root.on ? Theme.yellow : Qt.alpha(Theme.foreground, 0.45)
        scale: root._dragging ? 1.25 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
    }

    // Replaces BarHitArea so we can intercept drag gestures.
    MouseArea {
        id: hitArea
        hoverEnabled: true
        anchors.fill: parent
        anchors.topMargin:    -(Theme.barHeight - parent.height) / 2
        anchors.bottomMargin: -(Theme.barHeight - parent.height) / 2
        anchors.leftMargin:   -6
        anchors.rightMargin:  -6

        property real _pressY: 0

        onEntered: if (!root._dragging) tip.show(root)
        onExited:  if (!pressed) tip.hide()

        onPressed: mouse => {
            _pressY = mouseY
            tip.anchorItem = root
            tip.shown = true
        }

        onPositionChanged: mouse => {
            if (!pressed) return
            const dy = Math.max(0, mouseY - _pressY)
            if (dy >= 8) {
                if (!root._dragging) {
                    root._dragging = true
                    picker.close()
                    tip.hide()
                }
                root._dragMs = root._dragToMs(dy)
                root._cursorScreenY = hitArea.mapToGlobal(mouse.x, mouse.y).y
            }
        }

        onReleased: {
            if (root._dragging) {
                const ms = root._dragMs
                root._dragging = false
                // under 5 min → too short, treat as cancel
                if (ms === 0 || ms >= 5 * 60000) root.activate(ms)
            } else {
                tip.hide()
                picker.toggle()
            }
        }
    }

    // ── Hover tooltip ──────────────────────────────────────────────────
    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14
        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.on ? `Caffeinated · ${root.remaining}` : "Caffeinate"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    // ── Drag cursor label ──────────────────────────────────────────────
    // Floats next to the cursor while dragging so the user can see the
    // duration without looking back up at the bar.
    PanelWindow {
        id: dragLabel
        visible: root._dragging
        screen: root.Window.window?.screen ?? null
        anchors.top:  true
        anchors.left: true
        exclusiveZone: -1
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer:     WlrLayer.Overlay

        implicitWidth:  dlText.implicitWidth + 24
        implicitHeight: dlText.implicitHeight + 12

        WlrLayershell.margins.top: {
            const sy = screen?.y ?? 0
            return Math.max(Theme.barHeight + 4,
                            Math.round(root._cursorScreenY - sy - implicitHeight / 2))
        }
        WlrLayershell.margins.left: {
            const mid = root.mapToGlobal(root.width / 2, 0).x
            const sx  = screen?.x ?? 0
            return Math.max(0, Math.round(mid - sx - implicitWidth / 2))
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth

            Text {
                id: dlText
                anchors.centerIn: parent
                text: root._formatMs(root._dragMs)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                color: root._dragMs <= 0 ? Qt.alpha(Theme.foreground, 0.7) : Theme.yellow
            }
        }
    }

    // ── Duration option row ────────────────────────────────────────────
    component DurRow: Rectangle {
        property string label: ""
        property real   ms:    0   // 0 = indefinite

        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.smallRadius
        color: durMo.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: parent.label
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.foreground
        }
        MouseArea { id: durMo; anchors.fill: parent; hoverEnabled: true
                    onClicked: root.activate(parent.ms) }
    }

    // ── Duration picker popup ──────────────────────────────────────────
    BarPopup {
        id: picker
        anchorItem: root
        contentWidth:  200
        contentHeight: pcol.implicitHeight + 28

        ColumnLayout {
            id: pcol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            spacing: 2

            // Active state header
            RowLayout {
                visible: root.on
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 8

                Text {
                    text: ""
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.yellow
                }
                Text {
                    Layout.fillWidth: true
                    text: root.remaining
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Font.DemiBold
                    color: Theme.yellow
                }
                Rectangle {
                    implicitWidth:  offLbl.implicitWidth + 14
                    implicitHeight: 22; radius: height / 2
                    color: offMo.containsMouse ? Qt.alpha(Theme.red, 0.22) : Qt.alpha(Theme.red, 0.12)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text { id: offLbl; anchors.centerIn: parent; text: "Turn off"
                           font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; color: Theme.red }
                    MouseArea { id: offMo; anchors.fill: parent; hoverEnabled: true
                                onClicked: root.deactivate() }
                }
            }

            Rectangle {
                visible: root.on
                Layout.fillWidth: true; implicitHeight: Theme.borderWidth
                color: Theme.border; opacity: 0.5; Layout.bottomMargin: 4
            }

            Text {
                visible: !root.on
                text: "Caffeinate for"
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                font.weight: Font.DemiBold
                color: Qt.alpha(Theme.foreground, 0.5)
                Layout.bottomMargin: 4
            }

            DurRow { label: "15 minutes";   ms: 15 * 60 * 1000 }
            DurRow { label: "30 minutes";   ms: 30 * 60 * 1000 }
            DurRow { label: "45 minutes";   ms: 45 * 60 * 1000 }
            DurRow { label: "1 hour";       ms:      60 * 60 * 1000 }
            DurRow { label: "2 hours";      ms: 2  * 60 * 60 * 1000 }
            DurRow { label: "Indefinitely"; ms: 0 }
        }
    }
}
