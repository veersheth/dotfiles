import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import qs.common

// On-screen display for volume, brightness and keyboard backlight.
// Leaks in from the bottom edge as a canvas-drawn card.
Scope {
    id: root

    property string icon:  ""
    property real   value: 0
    property bool   muted: false
    property string message: ""
    property bool   shown: false

    property bool ready: false
    Timer { interval: 1200; running: true; onTriggered: root.ready = true }

    function show(icon, value, muted) {
        if (!ready) return;
        root.message = "";
        root.icon  = icon;
        root.value = value;
        root.muted = muted ?? false;
        shown = true;
        hideTimer.restart();
    }

    // text mode ("Charging — 2 h until full"); replaces the meter row
    function showMessage(icon, msg) {
        if (!ready) return;
        root.message = msg;
        root.icon  = icon;
        root.muted = false;
        iconPop.restart();
        shown = true;
        hideTimer.restart();
    }

    // messages need longer to be read than a glanceable meter
    Timer {
        id: hideTimer
        interval: root.message !== "" ? 2600 : 1600
        onTriggered: root.shown = false
    }

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

    // ── Charger events + low-battery nudges ───────────────────────────
    readonly property var battery: UPower.displayDevice
    property bool warned20: false
    property bool warned10: false

    function fmtMins(s) {
        const m = Math.round(s / 60);
        return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
    }
    function batteryIcon(pct) {
        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return icons[Math.min(9, Math.max(0, Math.floor(pct / 10)))];
    }

    Connections {
        target: root.battery
        enabled: root.battery?.isLaptopBattery ?? false

        function onStateChanged() {
            const b = root.battery;
            if (b.state === UPowerDeviceState.Charging) {
                root.warned20 = false;
                root.warned10 = false;
                const t = b.timeToFull;
                root.showMessage("󰂄", t > 0
                    ? `Charging - ${root.fmtMins(t)} until full` : "Charging");
            } else if (b.state === UPowerDeviceState.Discharging) {
                const t = b.timeToEmpty;
                root.showMessage(root.batteryIcon(b.percentage * 100), t > 0
                    ? `On battery - ${root.fmtMins(t)} remaining` : "On battery");
            } else if (b.state === UPowerDeviceState.FullyCharged) {
                root.showMessage("󰂅", "Fully charged");
            }
        }

        // one nudge per threshold per discharge cycle; flags reset on plug-in
        function onPercentageChanged() {
            const b = root.battery;
            if (b.state !== UPowerDeviceState.Discharging) return;
            const pct  = b.percentage * 100;
            const left = b.timeToEmpty > 0 ? ` - about ${root.fmtMins(b.timeToEmpty)} left` : "";
            if (pct <= 10 && !root.warned10) {
                root.warned10 = true;
                root.warned20 = true;
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Power",
                    "Battery critical", `${Math.round(pct)}% remaining${left}`]);
            } else if (pct <= 20 && !root.warned20) {
                root.warned20 = true;
                Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "Power",
                    "Battery low", `${Math.round(pct)}% remaining${left}`]);
            }
        }
    }

    // manual triggers for previewing: qs ipc call osd charging|discharging|full
    IpcHandler {
        target: "osd"

        function charging(): void {
            const t = root.battery?.timeToFull ?? 0;
            root.showMessage("󰂄", t > 0
                ? `Charging - ${root.fmtMins(t)} until full` : "Charging");
        }
        function discharging(): void {
            const b = root.battery;
            const t = b?.timeToEmpty ?? 0;
            root.showMessage(root.batteryIcon((b?.percentage ?? 0.5) * 100), t > 0
                ? `On battery - ${root.fmtMins(t)} remaining` : "On battery");
        }
        function full(): void {
            root.showMessage("󰂅", "Fully charged");
        }
    }

    // ── The card ──────────────────────────────────────────────────────
    PanelWindow {
        id: win

        readonly property int cardW: root.message !== ""
            ? Math.min(Math.round(msgText.implicitWidth + osdIcon.implicitWidth) + 50, 440)
            : 252
        readonly property int cardH: 64

        anchors.bottom: true
        exclusiveZone:  0
        WlrLayershell.margins.bottom: 32
        implicitWidth:  win.cardW
        implicitHeight: win.cardH
        color:          "transparent"
        visible:        root.shown || hideDelay.running
        mask: Region {}

        WlrLayershell.namespace: "quickshell:osd"
        WlrLayershell.layer: WlrLayer.Overlay

        NumberAnimation {
            id: enterAnim
            target: card; property: "opacity"
            from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: exitAnim
            target: card; property: "opacity"
            to: 0; duration: 140; easing.type: Easing.InCubic
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.popupRadius
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth
            opacity: 0
            clip: true

            Text {
                id: osdIcon
                anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                text:           root.icon
                font.family:    Theme.nerdFont
                font.pixelSize: 20
                color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
            }

            NumberAnimation {
                id: iconPop
                target: osdIcon; property: "scale"
                from: 0.5; to: 1
                duration: 380
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }

            Text {
                id: msgText
                anchors {
                    left: osdIcon.right; leftMargin: 10
                    right: parent.right; rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                visible: root.message !== ""
                elide: Text.ElideRight
                text: root.message
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Medium
                color: Theme.foreground
            }

            Rectangle {
                id: track
                visible: root.message === ""
                anchors {
                    left: parent.left;  leftMargin: 56
                    right: parent.right; rightMargin: 62
                    verticalCenter: parent.verticalCenter
                }
                height: 6
                radius: height / 2
                color:  Theme.hover

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Math.min(1, root.value) * parent.width
                    radius: height / 2
                    color:  root.muted ? Qt.alpha(Theme.foreground, 0.35) : Theme.blue
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: root.message === ""
                anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                text:           `${Math.round(root.value * 100)}%`
                font.family:    Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.weight:    Font.Medium
                color:          Theme.foreground
            }
        }

        Timer { id: hideDelay; interval: 280 }
    }

    onShownChanged: {
        if (shown) {
            exitAnim.stop()
            card.opacity = 0
            enterAnim.restart()
        } else {
            enterAnim.stop()
            exitAnim.restart()
            hideDelay.restart()
        }
    }
}
