import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// On-screen display for volume, brightness and keyboard backlight.
// Slides in from the right edge as a canvas-drawn pill.
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
    // rooted flush against the right edge so the bounce never detaches it.
    PanelWindow {
        id: win

        readonly property int cardW:   64
        readonly property int cardH:   252
        readonly property int flare:   14
        readonly property int cornerR: Theme.popupRadius

        property real progress: 0
        function lerp(a, b, t) { return a + (b - a) * t }
        readonly property real startW: 18
        readonly property real startH: 64
        readonly property real drawW:  lerp(startW, cardW, progress)
        readonly property real drawH:  lerp(startH, cardH, progress)

        anchors.right:  true
        exclusiveZone:  0
        // Slack so the OutBack overshoot grows into the window, not past it
        implicitWidth:  cardW + 12
        implicitHeight: cardH + flare * 2 + 24
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

                    const w    = width;
                    const m    = win.flare;
                    const dw   = win.drawW;
                    const dh   = win.drawH;
                    const yTop = (height - dh) / 2;
                    const yBot = yTop + dh;
                    const br   = Math.min(
                        win.lerp(win.startW / 2, win.cornerR, win.progress),
                        dw / 2, dh / 2);

                    ctx.beginPath();
                    ctx.moveTo(w, yTop - m);
                    ctx.arc(w - m, yTop - m, m, 0, Math.PI / 2, false);
                    ctx.lineTo(w - dw + br, yTop);
                    ctx.arc(w - dw + br, yTop + br, br, -Math.PI / 2, Math.PI, true);
                    ctx.lineTo(w - dw, yBot - br);
                    ctx.arc(w - dw + br, yBot - br, br, Math.PI, Math.PI / 2, true);
                    ctx.lineTo(w - m, yBot);
                    ctx.arc(w - m, yBot + m, m, -Math.PI / 2, 0, false);

                    ctx.fillStyle   = Theme.background;
                    ctx.fill();
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth   = Theme.borderWidth;
                    ctx.stroke();
                }
            }

            // Content clipped to the morphing card rect
            Item {
                anchors.right: parent.right
                y: (parent.height - win.drawH) / 2
                width:  win.drawW
                height: win.drawH
                clip: true

                Item {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width:  win.cardW
                    height: win.cardH
                    opacity: Math.max(0, (win.progress - 0.35) / 0.65)

                    Text {
                        anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
                        text:            root.icon
                        font.family:     Theme.nerdFont
                        font.pixelSize:  20
                        color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                    }

                    Rectangle {
                        id: track
                        anchors {
                            top: parent.top; topMargin: 48
                            bottom: parent.bottom; bottomMargin: 36
                            horizontalCenter: parent.horizontalCenter
                        }
                        width:  6
                        radius: 3
                        color:  Theme.hover

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: Math.min(1, root.value) * parent.height
                            radius: 3
                            color:  root.muted ? Qt.alpha(Theme.foreground, 0.35) : Theme.blue
                            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
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
