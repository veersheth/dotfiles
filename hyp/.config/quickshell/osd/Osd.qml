import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQml
import QtQuick
import qs.common

// On-screen display, split by screen edge so nothing overwrites anything else:
//   left   → volume
//   right  → display brightness + keyboard backlight
//   bottom → messages (charger, critical alerts) and Bluetooth connections
//
// Cards slide out of their edge on a fast-out, long-settle curve (no bounce)
// and slide back into it on exit.
Scope {
    id: root

    property bool ready: false
    Timer { interval: 1200; running: true; onTriggered: root.ready = true }

    // ── Public API ────────────────────────────────────────────────────
    // side: "left" | "right"  (defaults to right)
    function show(icon, value, muted, side) {
        if (!ready) return;
        (side === "left" ? leftOsd : rightOsd).showMeter(icon, value, muted ?? false);
    }

    function showMessage(icon, msg) {
        if (!ready) return;
        bottomOsd.showMessage(icon, msg);
    }

    // Rich Bluetooth-style device card (name, battery ring)
    function showDevice(icon, dev) {
        if (!ready) return;
        bottomOsd.showDevice(icon, dev);
    }

    // Persistent red-bordered OSD — stays until dismiss() is called.
    function showCritical(icon, msg) {
        if (!ready) return;
        bottomOsd.showCritical(icon, msg);
    }

    function dismiss() { bottomOsd.dismiss(); }

    // ── Volume (left) ─────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function showVolume() {
        const audio = sink?.audio;
        if (!audio) return;
        const icon = audio.muted ? "󰝟"
            : audio.volume < 0.33 ? "󰕿"
            : audio.volume < 0.66 ? "󰖀"
            : "󰕾";
        show(icon, audio.volume, audio.muted, "left");
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged()  { root.showVolume(); }
    }

    // ── Brightness + keyboard backlight (right) ───────────────────────
    property string backlightDev: ""
    property real   backlightMax: 1
    property string kbdDev:       ""
    property real   kbdMax:       1

    Process {
        running: true
        command: ["sh", "-c",
            'bl=$(ls /sys/class/backlight 2>/dev/null | head -n1); ' +
            'kbd=$(ls /sys/class/leds 2>/dev/null | grep kbd_backlight | head -n1); ' +
            'blmax=1; kbdmax=1; ' +
            '[ -n "$bl"  ] && blmax=$(cat "/sys/class/backlight/$bl/max_brightness"); ' +
            '[ -n "$kbd" ] && kbdmax=$(cat "/sys/class/leds/$kbd/max_brightness"); ' +
            'printf "%s|%s|%s|%s" "$bl" "$blmax" "$kbd" "$kbdmax"']
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("|");
                root.backlightDev = p[0] ?? "";
                root.backlightMax = Math.max(1, parseInt(p[1]) || 1);
                root.kbdDev       = p[2] ?? "";
                root.kbdMax       = Math.max(1, parseInt(p[3]) || 1);
            }
        }
    }

    // Only watch for keyboard-backlight changes automatically.
    // Display brightness OSD is triggered exclusively via IPC (see below).
    Process {
        running: root.kbdDev !== ""
        command: ["udevadm", "monitor", "-u", "-s", "leds"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("kbd_backlight")) readKbd.running = true;
            }
        }
    }

    Process {
        id: readBacklight
        command: ["cat", `/sys/class/backlight/${root.backlightDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim() || !root.backlightDev) return;
                const pct = (parseInt(text) || 0) / root.backlightMax;
                root.show(pct < 0.34 ? "󰃞" : pct < 0.67 ? "󰃟" : "󰃠", pct, false, "right");
            }
        }
    }

    // qs ipc call osd brightness   →  show current brightness level
    IpcHandler {
        target: "osd"
        function brightness(): void { readBacklight.running = true }
    }

    Process {
        id: readKbd
        command: ["cat", `/sys/class/leds/${root.kbdDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: root.show("󰌌", (parseInt(text) || 0) / root.kbdMax, false, "right")
        }
    }

    // ── Bluetooth connections (bottom) ────────────────────────────────
    // Devices already connected at startup are ignored because showDevice()
    // bails out until `ready` flips.
    property var btLast: ({})

    function btGlyph(icon) {
        const t = icon ?? "";
        if (t.includes("headset") || t.includes("headphones")) return "󰋋";
        if (t.includes("keyboard")) return "󰌌";
        if (t.includes("mouse"))    return "󰍽";
        if (t.includes("phone"))    return "󰏲";
        if (t.includes("audio-card") || t.includes("speaker")) return "󰓃";
        if (t.includes("gaming"))   return "󰊗";
        return "󰂱";
    }

    function btConnected(dev) {
        const now = Date.now();
        if (now - (btLast[dev.address] ?? 0) < 4000) return;   // ignore flapping
        btLast[dev.address] = now;
        showDevice(btGlyph(dev.icon), dev);
    }

    Instantiator {
        model: Bluetooth.devices
        delegate: QtObject {
            required property var modelData
            readonly property bool conn: modelData.connected
            onConnChanged: if (conn) root.btConnected(modelData)
            Component.onCompleted: if (conn) root.btConnected(modelData)
        }
    }

    // ── Charger events + low-battery nudges ───────────────────────────
    readonly property var battery: UPower.displayDevice
    property bool warned20: false
    property bool warned10: false

    Connections {
        target: root.battery
        enabled: root.battery?.isLaptopBattery ?? false

        function onStateChanged() {
            const b = root.battery;
            if (!b) return;
            if (b.state === UPowerDeviceState.Charging ||
                b.state === UPowerDeviceState.FullyCharged) {
                root.warned20 = false;
                root.warned10 = false;
            }
        }

        // One flash per threshold per discharge cycle; flags reset on plug-in.
        function onPercentageChanged() {
            const b = root.battery;
            if (b.state !== UPowerDeviceState.Discharging) return;
            const pct = b.percentage * 100;
            if (pct <= 10 && !root.warned10) {
                root.warned10 = true;
                root.warned20 = true;
                FlashService.trigger(Theme.red, 2000);
            } else if (pct <= 20 && !root.warned20) {
                root.warned20 = true;
                FlashService.trigger(Theme.red, 2000);
            }
        }
    }

    // ── The three edge windows ────────────────────────────────────────
    EdgeOsd { id: leftOsd;   edge: "left" }
    EdgeOsd { id: rightOsd;  edge: "right" }
    EdgeOsd { id: bottomOsd; edge: "bottom" }

    // ══════════════════════════════════════════════════════════════════
    // One OSD surface glued to one screen edge. `dist` is how far the
    // card's inner face sits from that edge; the window is flush with the
    // edge, so a negative `dist` means the card is still tucked inside it.
    // ══════════════════════════════════════════════════════════════════
    component EdgeOsd: PanelWindow {
        id: win

        required property string edge            // "left" | "right" | "bottom"
        readonly property bool vertical: edge !== "bottom"

        // content state
        property string icon:       ""
        property real   value:      0
        property bool   muted:      false
        property string message:    ""
        property bool   critical:   false
        property bool   persistent: false
        property bool   shown:      false

        // rich Bluetooth card state
        property bool rich:     false
        property var  device:   null
        property real nameT:    1       // 0→1 reveal progress for the name
        readonly property real batteryPct:
            (device?.batteryAvailable ?? false) ? Math.round((device?.battery ?? 0) * 100) : -1

        // animation state
        property bool alive: false      // window mapped (covers the exit slide)
        property real dist: -cardA

        // geometry
        readonly property int cardA: rich ? 76 : 64              // thickness (toward the screen)
        readonly property int cardL: vertical ? 220              // length (along the edge)
            : rich
                ? Math.max(210, Math.min(18 + 52 + 14 + nameText.implicitWidth + 30, 420))
            : message !== ""
                ? Math.max(170, Math.min(Math.round(msgText.implicitWidth + osdIcon.implicitWidth) + 50, 440))
                : 252
        readonly property int dRest: vertical ? 20 : (BarState.barBottom ? 10 : 24)
        readonly property int winU: dRest + cardA + 6

        // ── API ───────────────────────────────────────────────────────
        function showMeter(ic, v, m) {
            critical = false; persistent = false; rich = false; message = "";
            icon = ic; value = v; muted = m;
            shown = true;
            hideTimer.restart();
        }

        function showMessage(ic, msg) {
            critical = false; persistent = false; rich = false;
            message = msg; icon = ic; muted = false;
            iconPop.restart();
            shown = true;
            hideTimer.restart();
        }

        function showDevice(ic, dev) {
            critical = false; persistent = false; rich = true;
            device = dev;
            message = dev.name ?? dev.address;
            icon = ic; muted = false;
            badgeAnim.restart();
            revealAnim.restart();
            shown = true;
            hideTimer.restart();
        }

        function showCritical(ic, msg) {
            critical = true; persistent = true; rich = false;
            message = msg; icon = ic; muted = false;
            iconPop.restart();
            shown = true;
            hideTimer.stop();
        }

        function dismiss() {
            persistent = false;
            critical = false;
            shown = false;
        }

        Timer {
            id: hideTimer
            interval: win.rich ? 3600 : win.message !== "" ? 2600 : 1600
            onTriggered: if (!win.persistent) win.shown = false
        }

        // ── Window ────────────────────────────────────────────────────
        anchors.bottom: edge === "bottom"
        anchors.left:   edge === "left"
        anchors.right:  edge === "right"
        exclusiveZone:  0
        WlrLayershell.margins.bottom: edge === "bottom" && BarState.barBottom ? Theme.barHeight : 0
        implicitWidth:  vertical ? winU : cardL
        implicitHeight: vertical ? cardL : winU
        color:   "transparent"
        visible: alive
        mask: Region {}

        WlrLayershell.namespace: "quickshell:osd"
        WlrLayershell.layer: WlrLayer.Overlay

        // ── Slide in: quick out of the edge, long soft settle ─────────
        NumberAnimation {
            id: enterAnim
            target: win; property: "dist"; to: win.dRest
            duration: 460
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
        }

        // ── Slide out: eases in, then is gone ─────────────────────────
        SequentialAnimation {
            id: exitAnim
            NumberAnimation {
                target: win; property: "dist"; to: -win.cardA
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.7, 0.0, 0.84, 0.0, 1.0, 1.0]
            }
            ScriptAction { script: win.alive = false }
        }

        onShownChanged: {
            if (shown) {
                exitAnim.stop();
                if (!alive) {
                    dist = -cardA;
                    alive = true;
                }
                enterAnim.restart();
            } else {
                enterAnim.stop();
                exitAnim.restart();
            }
        }

        // ── The card ──────────────────────────────────────────────────
        Rectangle {
            id: card
            width:  win.vertical ? win.cardA : win.cardL
            height: win.vertical ? win.cardL : win.cardA
            x: win.edge === "left"  ? win.dist
             : win.edge === "right" ? win.width - win.dist - width
             : (win.width - width) / 2
            y: win.edge === "bottom" ? win.height - win.dist - height
             : (win.height - height) / 2

            radius: Theme.popupRadius + (win.rich ? 6 : 0)
            color: win.critical ? Qt.rgba(
                Theme.red.r * 0.18, Theme.red.g * 0.18, Theme.red.b * 0.18, 0.96)
                : Theme.surface
            border.color: win.critical ? Qt.alpha(Theme.red, 0.7) : Theme.border
            border.width: win.critical ? 2 : Theme.borderWidth
            clip: true

            Behavior on color        { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // ── Classic content: icon + message / vertical meter ──────
            Text {
                id: osdIcon
                visible: !win.rich
                x: win.vertical ? (card.width - implicitWidth) / 2 : 20
                y: win.vertical ? 16 : (card.height - implicitHeight) / 2
                text:           win.icon
                font.family:    Theme.nerdFont
                font.pixelSize: 20
                color: win.critical ? Theme.red
                     : win.muted    ? Qt.alpha(Theme.foreground, 0.4)
                     : Theme.foreground
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            NumberAnimation {
                id: iconPop
                target: osdIcon; property: "scale"
                from: 0.6; to: 1
                duration: 380
                easing.type: Easing.OutCubic
            }

            Text {
                id: msgText
                visible: !win.vertical && !win.rich
                anchors {
                    left: osdIcon.right; leftMargin: 10
                    right: parent.right; rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                elide: Text.ElideRight
                text: win.message
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Medium
                color: win.critical ? Theme.red : Theme.foreground
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                id: track
                visible: win.vertical
                width: 6
                radius: width / 2
                color: Theme.hover
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top;       topMargin: 56
                    bottom: parent.bottom; bottomMargin: 46
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: Math.min(1, win.value) * parent.height
                    radius: width / 2
                    color:  win.muted ? Qt.alpha(Theme.foreground, 0.35) : Theme.blue
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: win.vertical
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
                text:           `${Math.round(win.value * 100)}%`
                font.family:    Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.weight:    Font.Medium
                color:          Theme.foreground
            }

            // ── Rich content: Bluetooth device card ───────────────────
            Item {
                id: richContent
                visible: win.rich
                anchors.fill: parent

                // icon badge: glyph inside a battery progress ring
                Item {
                    id: badge
                    x: 18
                    y: (parent.height - height) / 2
                    width: 52; height: 52

                    // tinted disc, inset so the ring sits around it
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: width / 2
                        color: Qt.alpha(Theme.blue, 0.18)
                    }

                    // battery ring
                    Canvas {
                        id: batRing
                        anchors.fill: parent
                        antialiasing: true

                        property real progress: 0
                        readonly property real pct: win.batteryPct

                        onProgressChanged: requestPaint()
                        onPctChanged: if (!badgeAnim.running) progress = pct >= 0 ? pct / 100 : 0

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const c = width / 2;
                            const r = c - 2;
                            ctx.lineWidth = 3;
                            ctx.lineCap = "round";

                            // faint track
                            ctx.strokeStyle = Qt.alpha(Theme.green, 0.2);
                            ctx.beginPath();
                            ctx.arc(c, c, r, 0, Math.PI * 2);
                            ctx.stroke();

                            // progress, starting at 12 o'clock
                            if (pct >= 0 && progress > 0) {
                                ctx.strokeStyle = Theme.green;
                                ctx.beginPath();
                                ctx.arc(c, c, r, -Math.PI / 2,
                                        -Math.PI / 2 + Math.PI * 2 * progress);
                                ctx.stroke();
                            }
                        }
                    }

                    Text {
                        id: badgeGlyph
                        anchors.centerIn: parent
                        text: win.icon
                        font.family: Theme.nerdFont
                        font.pixelSize: 22
                        color: Theme.blue
                    }
                }

                // badge grows in, glyph makes one turn, ring fills up
                ParallelAnimation {
                    id: badgeAnim
                    NumberAnimation {
                        target: badge; property: "scale"; from: 0.65; to: 1
                        duration: 520
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                    }
                    NumberAnimation {
                        target: badgeGlyph; property: "rotation"; from: -180; to: 0
                        duration: 800; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: batRing; property: "progress"
                        from: 0; to: win.batteryPct >= 0 ? win.batteryPct / 100 : 0
                        duration: 900; easing.type: Easing.OutCubic
                    }
                }

                // name reveal
                SequentialAnimation {
                    id: revealAnim
                    PropertyAction { target: win; property: "nameT"; value: 0 }
                    PauseAnimation { duration: 140 }
                    NumberAnimation { target: win; property: "nameT"; to: 1; duration: 320; easing.type: Easing.OutCubic }
                }

                Text {
                    id: nameText
                    x: 18 + 52 + 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.message
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Font.DemiBold
                    color: Theme.foreground
                    opacity: win.nameT
                    transform: Translate { x: (1 - win.nameT) * 10 }
                }
            }
        }
    }
}

