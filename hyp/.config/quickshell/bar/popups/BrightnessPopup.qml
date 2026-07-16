import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    contentWidth:  280
    contentHeight: col.implicitHeight + 40

    property string backlightDev: ""
    property real   backlightMax: 1
    property string kbdDev:       ""
    property real   kbdMax:       1

    property real brightness:    0
    property real kbdBrightness: 0

    readonly property bool hasDisplay: backlightDev !== ""
    readonly property bool hasKbd:     kbdDev       !== ""

    // ── Device detection (runs once on bar startup) ────────────────────
    Process {
        id: detectProc
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
                const p = text.trim().split("|")
                root.backlightDev = p[0] ?? ""
                root.backlightMax = Math.max(1, parseInt(p[1]) || 1)
                root.kbdDev       = p[2] ?? ""
                root.kbdMax       = Math.max(1, parseInt(p[3]) || 1)
                root.readAll()
            }
        }
    }

    // ── Read current values ────────────────────────────────────────────
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

    // Poll while the popup is open so keyboard shortcuts are reflected
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.shown && root.hasDisplay
        onTriggered: root.readAll()
    }

    // ── Set brightness (debounced to avoid flooding brightnessctl) ─────
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

    // ── Layout ─────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
        spacing: 16

        // ── Display brightness ─────────────────────────────────────────
        ColumnLayout {
            visible: root.hasDisplay
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Brightness"
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
                color: Qt.alpha(Theme.foreground, 0.55)
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Text {
                    text: root.brightness < 0.34 ? "󰃞"
                        : root.brightness < 0.67 ? "󰃟"
                        : "󰃠"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: Theme.foreground
                }

                Item {
                    Layout.fillWidth: true; height: 20

                    Rectangle {
                        id: blTrack
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: 4; radius: 2
                        color: Qt.alpha(Theme.foreground, 0.12)

                        Rectangle {
                            width: root.brightness * parent.width
                            height: parent.height; radius: 2
                            color: Theme.blue
                            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            x: Math.max(0, Math.min(blTrack.width - width,
                                root.brightness * blTrack.width - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14; radius: 7; color: "white"; z: 1
                            scale: blArea.containsMouse || blArea.pressed ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                        }

                        MouseArea {
                            id: blArea
                            anchors { fill: parent; margins: -8 }
                            hoverEnabled: true
                            onPressed:         ev => root.setDisplay(ev.x / blTrack.width)
                            onPositionChanged: ev => { if (pressed) root.setDisplay(ev.x / blTrack.width) }
                        }
                    }
                }

                Text {
                    text: `${Math.round(root.brightness * 100)}%`
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium
                    color: Qt.alpha(Theme.foreground, 0.70)
                    Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ── Keyboard backlight ─────────────────────────────────────────
        ColumnLayout {
            visible: root.hasKbd
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Keyboard"
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
                color: Qt.alpha(Theme.foreground, 0.55)
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Text {
                    text: "󰌌"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: root.kbdBrightness > 0
                        ? Theme.foreground : Qt.alpha(Theme.foreground, 0.35)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item {
                    Layout.fillWidth: true; height: 20

                    Rectangle {
                        id: kbdTrack
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: 4; radius: 2
                        color: Qt.alpha(Theme.foreground, 0.12)

                        Rectangle {
                            width: root.kbdBrightness * parent.width
                            height: parent.height; radius: 2
                            color: Theme.blue
                            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            x: Math.max(0, Math.min(kbdTrack.width - width,
                                root.kbdBrightness * kbdTrack.width - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14; radius: 7; color: "white"; z: 1
                            scale: kbdArea.containsMouse || kbdArea.pressed ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                        }

                        MouseArea {
                            id: kbdArea
                            anchors { fill: parent; margins: -8 }
                            hoverEnabled: true
                            onPressed:         ev => root.setKbd(ev.x / kbdTrack.width)
                            onPositionChanged: ev => { if (pressed) root.setKbd(ev.x / kbdTrack.width) }
                        }
                    }
                }

                Text {
                    text: `${Math.round(root.kbdBrightness * 100)}%`
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium
                    color: Qt.alpha(Theme.foreground, 0.70)
                    Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight
                }
            }
        }

        // No devices found
        Text {
            visible: !root.hasDisplay && !root.hasKbd && !detectProc.running
            Layout.fillWidth: true
            text: "No backlight device found"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            color: Qt.alpha(Theme.foreground, 0.45)
        }
    }
}
