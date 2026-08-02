import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    contentWidth:  Theme.listWidth + 2 * contentPadding
    contentHeight: col.implicitHeight + 2 * contentPadding

    // ── WiFi state (fed from QuickSettings bar item) ──────────────────────
    property bool   wifiEnabled:    false
    property bool   wifiConnected:  false
    property int    wifiStrength:   0
    property string ssid:           ""
    property bool   wifiNoInternet: false

    signal wifiToggled()
    signal wifiDrillDown()

    // ── Bluetooth ─────────────────────────────────────────────────────────
    readonly property var  btAdapter:   Bluetooth.defaultAdapter
    readonly property bool btEnabled:   btAdapter?.enabled ?? false
    readonly property var  btConnected: btEnabled
        ? Bluetooth.devices.values.filter(d => d.connected) : []

    signal btDrillDown()

    // ── Volume ────────────────────────────────────────────────────────────
    readonly property var  sink:   Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false

    PwObjectTracker { objects: [root.sink] }

    // ── Microphone ────────────────────────────────────────────────────────
    readonly property var  micSource: Pipewire.defaultAudioSource
    readonly property real micVolume: micSource?.audio?.volume ?? 0
    readonly property bool micMuted:  micSource?.audio?.muted  ?? false
    PwObjectTracker { objects: [root.micSource] }

    signal volumeDrillDown()
    signal micDrillDown()

    // ── Brightness ────────────────────────────────────────────────────────
    property string backlightDev: ""
    property real   backlightMax: 1
    property string kbdDev:       ""
    property real   kbdMax:       1
    property real   brightness:    0
    property real   kbdBrightness: 0

    readonly property bool hasDisplay: backlightDev !== ""
    readonly property bool hasKbd:     kbdDev       !== ""

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    // ── Device detection (runs once at bar startup) ───────────────────────
    Process {
        id: detectProc; running: true
        command: ["sh", "-c",
            'bl=$(ls /sys/class/backlight 2>/dev/null | head -n1); ' +
            'kbd=$(ls /sys/class/leds 2>/dev/null | grep kbd_backlight | head -n1); ' +
            'blmax=1; kbdmax=1; ' +
            '[ -n "$bl"  ] && blmax=$(cat "/sys/class/backlight/$bl/max_brightness"); ' +
            '[ -n "$kbd" ] && kbdmax=$(cat "/sys/class/leds/$kbd/max_brightness"); ' +
            'printf "%s|%s|%s|%s" "$bl" "$blmax" "$kbd" "$kbdmax"']
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                root.backlightDev = p[0] ?? ""
                root.backlightMax = Math.max(1, parseInt(p[1]) || 1)
                root.kbdDev       = p[2] ?? ""
                root.kbdMax       = Math.max(1, parseInt(p[3]) || 1)
                root.readAll()
            }
        }
    }

    function readAll() {
        if (hasDisplay) readBlProc.running  = true
        if (hasKbd)     readKbdProc.running = true
    }

    Process {
        id: readBlProc
        command: ["cat", `/sys/class/backlight/${root.backlightDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: root.brightness = Math.max(0, Math.min(1,
                (parseInt(text) || 0) / root.backlightMax))
        }
    }
    Process {
        id: readKbdProc
        command: ["cat", `/sys/class/leds/${root.kbdDev}/brightness`]
        stdout: StdioCollector {
            onStreamFinished: root.kbdBrightness = Math.max(0, Math.min(1,
                (parseInt(text) || 0) / root.kbdMax))
        }
    }

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.shown && root.hasDisplay
        onTriggered: root.readAll()
    }

    Process { id: setBlProc;  stdout: StdioCollector {} }
    Process { id: setKbdProc; stdout: StdioCollector {} }

    Timer {
        id: blTimer; interval: 40
        property real pending: -1
        onTriggered: {
            if (pending < 0 || setBlProc.running) return
            setBlProc.command = ["brightnessctl", "set", `${Math.round(pending * 100)}%`]
            setBlProc.running = true; pending = -1
        }
    }
    Timer {
        id: kbdTimer; interval: 40
        property real pending: -1
        onTriggered: {
            if (pending < 0 || setKbdProc.running) return
            setKbdProc.command = ["brightnessctl", `--device=${root.kbdDev}`,
                                  "set", `${Math.round(pending * 100)}%`]
            setKbdProc.running = true; pending = -1
        }
    }

    function setDisplay(frac) {
        root.brightness = Math.max(0, Math.min(1, frac))
        blTimer.pending = root.brightness; blTimer.restart()
    }
    function setKbd(frac) {
        root.kbdBrightness = Math.max(0, Math.min(1, frac))
        kbdTimer.pending = root.kbdBrightness; kbdTimer.restart()
    }

    // ── Layout ─────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 16

        // ── WiFi pill (full-width row) ──────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 60; radius: 16
            color: root.wifiEnabled ? Qt.alpha(Theme.blue, 0.14) : Qt.alpha(Theme.foreground, 0.05)
            border.color: Qt.alpha(Theme.foreground, 0.08); border.width: 1; clip: true
            Behavior on color { ColorAnimation { duration: 200 } }

            MouseArea { anchors.fill: parent; onClicked: root.wifiDrillDown() }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                spacing: 12

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: root.wifiEnabled ? Theme.blue : Qt.alpha(Theme.foreground, 0.14)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: root.wifiConnected
                            ? root.wifiIcons[Math.max(0, Math.min(4, Math.round(root.wifiStrength / 25)))]
                            : root.wifiEnabled ? "󰤯" : "󰤭"
                        font.family: Theme.nerdFont; font.pixelSize: 16
                        color: root.wifiEnabled ? "white" : Qt.alpha(Theme.foreground, 0.45)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: "Wi-Fi"; font.family: Theme.font
                        font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
                        color: Theme.foreground
                    }
                    Text {
                        Layout.fillWidth: true; elide: Text.ElideRight
                        text: root.wifiNoInternet ? "No internet"
                            : root.wifiConnected  ? root.ssid
                            : root.wifiEnabled    ? "Not connected" : "Off"
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        color: root.wifiNoInternet ? Theme.yellow : Qt.alpha(Theme.foreground, 0.5)
                    }
                }

                PopupToggle { checked: root.wifiEnabled; onToggled: root.wifiToggled() }

                Text {
                    text: "󰅂"; font.family: Theme.nerdFont; font.pixelSize: 13
                    color: Qt.alpha(Theme.foreground, wifiMoreMo.containsMouse ? 0.8 : 0.28)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    MouseArea {
                        id: wifiMoreMo
                        anchors { fill: parent; margins: -8 }
                        hoverEnabled: true
                        onClicked: root.wifiDrillDown()
                    }
                }
            }
        }

        // ── Bluetooth pill ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 60; radius: 16
            color: root.btEnabled ? Qt.alpha(Theme.blue, 0.14) : Qt.alpha(Theme.foreground, 0.05)
            border.color: Qt.alpha(Theme.foreground, 0.08); border.width: 1; clip: true
            Behavior on color { ColorAnimation { duration: 200 } }

            MouseArea { anchors.fill: parent; onClicked: root.btDrillDown() }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                spacing: 12

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: root.btEnabled ? Theme.blue : Qt.alpha(Theme.foreground, 0.14)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: root.btConnected.length > 0 ? "󰂱" : root.btEnabled ? "󰂯" : "󰂲"
                        font.family: Theme.nerdFont; font.pixelSize: 16
                        color: root.btEnabled ? "white" : Qt.alpha(Theme.foreground, 0.45)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: "Bluetooth"; font.family: Theme.font
                        font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
                        color: Theme.foreground
                    }
                    Text {
                        Layout.fillWidth: true; elide: Text.ElideRight
                        text: {
                            if (!root.btEnabled) return "Off"
                            const n = root.btConnected.length
                            if (n === 0) return "On"
                            if (n === 1) return root.btConnected[0]?.name ?? "Connected"
                            return `${n} connected`
                        }
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        color: Qt.alpha(Theme.foreground, 0.5)
                    }
                }

                PopupToggle {
                    checked: root.btEnabled
                    onToggled: if (root.btAdapter) root.btAdapter.enabled = !root.btAdapter.enabled
                }

                Text {
                    text: "󰅂"; font.family: Theme.nerdFont; font.pixelSize: 13
                    color: Qt.alpha(Theme.foreground, btMoreMo.containsMouse ? 0.8 : 0.28)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    MouseArea {
                        id: btMoreMo
                        anchors { fill: parent; margins: -8 }
                        hoverEnabled: true
                        onClicked: root.btDrillDown()
                    }
                }
            }
        }

        // ── Divider ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: Qt.alpha(Theme.foreground, 0.08)
        }

        // ── Volume ────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; spacing: 10

            Item {
                Layout.fillWidth: true
                implicitHeight: volHdrRow.implicitHeight

                RowLayout {
                    id: volHdrRow
                    anchors.fill: parent; spacing: 4

                    Text {
                        text: "Volume"; font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                        color: Qt.alpha(Theme.foreground, 0.60)
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: `${Math.round(root.volume * 100)}%`
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        color: root.volume > 1.0 ? Theme.yellow : Qt.alpha(Theme.foreground, 0.50)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        text: "󰅂"; font.family: Theme.nerdFont; font.pixelSize: 13
                        color: Qt.alpha(Theme.foreground, volHdrMo.containsMouse ? 0.75 : 0.28)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
                MouseArea {
                    id: volHdrMo; anchors.fill: parent; hoverEnabled: true
                    onClicked: root.volumeDrillDown()
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Text {
                    text: root.muted ? "󰝟" : root.volume < 0.33 ? "󰕿" : root.volume < 0.66 ? "󰖀" : "󰕾"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: muteMo
                        anchors { fill: parent; margins: -6 }
                        hoverEnabled: true
                        onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.muted
                    }
                }

                CommonSlider {
                    Layout.fillWidth: true
                    value:     root.volume
                    maxValue:  1.5
                    tickAt:    1.0
                    fillColor: root.muted ? Qt.alpha(Theme.foreground, 0.28)
                             : root.volume > 1.0 ? Theme.yellow : Theme.blue
                    onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
                }
            }
        }

        // ── Microphone ────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; spacing: 10

            Item {
                Layout.fillWidth: true
                implicitHeight: micHdrRow.implicitHeight

                RowLayout {
                    id: micHdrRow
                    anchors.fill: parent; spacing: 4

                    Text {
                        text: "Microphone"; font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                        color: Qt.alpha(Theme.foreground, 0.60)
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: `${Math.round(root.micVolume * 100)}%`
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        color: Qt.alpha(Theme.foreground, 0.50)
                    }
                    Text {
                        text: "󰅂"; font.family: Theme.nerdFont; font.pixelSize: 13
                        color: Qt.alpha(Theme.foreground, micHdrMo.containsMouse ? 0.75 : 0.28)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
                MouseArea {
                    id: micHdrMo; anchors.fill: parent; hoverEnabled: true
                    onClicked: root.micDrillDown()
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: root.micMuted ? "󰍭" : "󰍬"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: root.micMuted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: micMuteMo
                        anchors { fill: parent; margins: -6 }
                        hoverEnabled: true
                        onClicked: if (root.micSource?.audio) root.micSource.audio.muted = !root.micMuted
                    }
                }
                CommonSlider {
                    Layout.fillWidth: true
                    value:     root.micVolume
                    maxValue:  1.0
                    fillColor: root.micMuted ? Qt.alpha(Theme.foreground, 0.28) : Theme.blue
                    onMoved: v => { if (root.micSource?.audio) root.micSource.audio.volume = v }
                }
            }
        }

        // ── Divider between audio and backlight groups ────────────────────
        Rectangle {
            visible: root.hasDisplay || root.hasKbd
            Layout.fillWidth: true; height: 1
            color: Qt.alpha(Theme.foreground, 0.08)
        }

        // ── Brightness ────────────────────────────────────────────────────
        ColumnLayout {
            visible: root.hasDisplay; Layout.fillWidth: true; spacing: 10

            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text {
                    text: "Brightness"; font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                    color: Qt.alpha(Theme.foreground, 0.60)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: `${Math.round(root.brightness * 100)}%`
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.foreground, 0.50)
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: root.brightness < 0.34 ? "󰃞" : root.brightness < 0.67 ? "󰃟" : "󰃠"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: Theme.foreground
                }
                CommonSlider {
                    Layout.fillWidth: true
                    value:   root.brightness
                    onMoved: v => root.setDisplay(v)
                }
            }
        }

        // ── Keyboard backlight ────────────────────────────────────────────
        ColumnLayout {
            visible: root.hasKbd; Layout.fillWidth: true; spacing: 10

            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text {
                    text: "Keyboard"; font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                    color: Qt.alpha(Theme.foreground, 0.60)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: `${Math.round(root.kbdBrightness * 100)}%`
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.foreground, 0.50)
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: "󰌌"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: root.kbdBrightness > 0 ? Theme.foreground : Qt.alpha(Theme.foreground, 0.35)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                CommonSlider {
                    Layout.fillWidth: true
                    value:   root.kbdBrightness
                    onMoved: v => root.setKbd(v)
                }
            }
        }
    }
}
