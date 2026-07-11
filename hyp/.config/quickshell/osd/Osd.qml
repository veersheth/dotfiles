import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// On-screen display for volume, brightness and keyboard backlight.
// Leaks in from the bottom edge as a canvas-drawn card.
Scope {
    id: root

    property string icon:  ""
    property real   value: 0
    property bool   muted: false
    property bool   shown: false

    property bool ready: false
    Timer { interval: 1200; running: true; onTriggered: root.ready = true }

    function show(icon, value, muted) {
        if (!ready) return;
        root.icon  = icon;
        root.value = value;
        root.muted = muted ?? false;
        shown = true;
        hideTimer.restart();
    }

    Timer { id: hideTimer; interval: 1600; onTriggered: root.shown = false }

    // ── Volume ────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function showVolume() {
        const audio = sink?.audio;
        if (!audio) return;
        const icon = audio.muted ? "󰝟"
            : audio.volume < 0.33 ? "󰕿"
            : audio.volume < 0.66 ? "󰖀"
            : "󰕾";
        show(icon, audio.volume, audio.muted);
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged()  { root.showVolume(); }
    }

    // ── Brightness + keyboard backlight ───────────────────────────────
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

    Process {
        running: root.backlightDev !== "" || root.kbdDev !== ""
        command: ["udevadm", "monitor", "-u", "-s", "backlight", "-s", "leds"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("kbd_backlight")) readKbd.running = true;
                else if (line.includes("backlight")) readBacklight.running = true;
            }
        }
    }

    Process {
        id: readBacklight
        command: ["cat", `/sys/class/backlight/${root.backlightDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = (parseInt(text) || 0) / root.backlightMax;
                root.show(pct < 0.34 ? "󰃞" : pct < 0.67 ? "󰃟" : "󰃠", pct);
            }
        }
    }

    Process {
        id: readKbd
        command: ["cat", `/sys/class/leds/${root.kbdDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: root.show("󰌌", (parseInt(text) || 0) / root.kbdMax)
        }
    }

    // ── The card ──────────────────────────────────────────────────────
    // Morphs from a small nub into the full card (same as BarPopup), always
    // rooted flush against the bottom edge so the bounce never detaches it.
    PanelWindow {
        id: win

        readonly property int cardW:   252
        readonly property int cardH:   64
        readonly property int flare:   14
        readonly property int cornerR: Theme.popupRadius

        property real progress: 0
        function lerp(a, b, t) { return a + (b - a) * t }
        readonly property real startW: 64
        readonly property real startH: 18
        readonly property real drawW:  lerp(startW, cardW, progress)
        readonly property real drawH:  lerp(startH, cardH, progress)

        anchors.bottom: true
        exclusiveZone:  0
        // Slack so the OutBack overshoot grows into the window, not past it
        implicitWidth:  cardW + flare * 2 + 24
        implicitHeight: cardH + 12
        color:          "transparent"
        visible:        root.shown || hideDelay.running
        mask: Region {}

        WlrLayershell.namespace: "quickshell:osd"
        WlrLayershell.layer: WlrLayer.Overlay

        NumberAnimation {
            id: enterAnim
            target: win; property: "progress"
            to: 1; duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
        NumberAnimation {
            id: exitAnim
            target: win; property: "progress"
            to: 0; duration: 160; easing.type: Easing.InCubic
        }

        Item {
            id: slider
            anchors.fill: parent
            opacity: Math.min(1, win.progress * 4)
            visible: win.progress > 0

            Canvas {
                anchors.fill: parent

                readonly property real cw:  win.drawW
                readonly property real chh: win.drawH
                onCwChanged:  requestPaint()
                onChhChanged: requestPaint()
                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const W  = width;
                    const H  = height;
                    const m  = win.flare;
                    const dw = win.drawW;
                    const dh = win.drawH;
                    const xL = (W - dw) / 2;
                    const xR = xL + dw;
                    const br = Math.min(
                        win.lerp(win.startH / 2, win.cornerR, win.progress),
                        dw / 2, dh / 2);

                    ctx.beginPath();
                    ctx.moveTo(xL - m, H);
                    ctx.arc(xL - m, H - m, m, Math.PI / 2, 0, true);
                    ctx.lineTo(xL, H - dh + br);
                    ctx.arc(xL + br, H - dh + br, br, Math.PI, Math.PI * 1.5, false);
                    ctx.lineTo(xR - br, H - dh);
                    ctx.arc(xR - br, H - dh + br, br, Math.PI * 1.5, Math.PI * 2, false);
                    ctx.lineTo(xR, H - m);
                    ctx.arc(xR + m, H - m, m, Math.PI, Math.PI / 2, true);

                    ctx.fillStyle   = Theme.background;
                    ctx.fill();
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth   = Theme.borderWidth;
                    ctx.stroke();
                }
            }

            // Content clipped to the morphing card rect
            Item {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width:  win.drawW
                height: win.drawH
                clip: true

                Item {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width:  win.cardW
                    height: win.cardH
                    opacity: Math.max(0, (win.progress - 0.35) / 0.65)

                    Text {
                        id: osdIcon
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        text:           root.icon
                        font.family:    Theme.nerdFont
                        font.pixelSize: 20
                        color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                    }

                    Rectangle {
                        id: track
                        anchors {
                            left: parent.left;  leftMargin: 56
                            right: parent.right; rightMargin: 62
                            verticalCenter: parent.verticalCenter
                        }
                        height: 6
                        radius: 3
                        color:  Theme.hover

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: Math.min(1, root.value) * parent.width
                            radius: 3
                            color:  root.muted ? Qt.alpha(Theme.foreground, 0.35) : Theme.blue
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                        text:           `${Math.round(root.value * 100)}%`
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        font.weight:    Font.Medium
                        color:          Theme.foreground
                    }
                }
            }
        }

        Timer { id: hideDelay; interval: 280 }
    }

    onShownChanged: {
        if (shown) { exitAnim.stop(); enterAnim.restart(); }
        else       { enterAnim.stop(); exitAnim.restart(); hideDelay.restart(); }
    }
}
