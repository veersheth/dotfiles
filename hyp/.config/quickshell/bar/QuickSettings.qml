import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Unified quick-settings bar item. Shows wifi/bt/volume status icons.
// Click to open the combined panel; the panel's drill-down buttons open
// the full WifiPopup, BluetoothPopup, or VolumePopup.
Item {
    id: root

    // ── WiFi state ────────────────────────────────────────────────────────
    property bool   wifiEnabled:      true
    property bool   wifiConnected:    false
    property int    wifiStrength:     0
    property string ssid:             ""
    property string wifiConnectivity: "unknown"
    readonly property bool wifiNoInternet:
        wifiConnected && (wifiConnectivity === "none"
            || wifiConnectivity === "limited"
            || wifiConnectivity === "portal")

    // ── Bluetooth (live from Quickshell.Bluetooth) ────────────────────────
    readonly property var  btAdapter:   Bluetooth.defaultAdapter
    readonly property bool btEnabled:   btAdapter?.enabled ?? false
    readonly property var  btConnected: btEnabled
        ? Bluetooth.devices.values.filter(d => d.connected) : []

    // ── Volume (live from Pipewire) ───────────────────────────────────────
    readonly property var  volSink: Pipewire.defaultAudioSink
    readonly property real volume:  volSink?.audio?.volume ?? 0
    readonly property bool muted:   volSink?.audio?.muted  ?? false
    PwObjectTracker { objects: [root.volSink] }

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    Layout.alignment: Qt.AlignVCenter
    implicitWidth:  iconsRow.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    // ── Status icon cluster ───────────────────────────────────────────────
    Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: 7

        Item {
            width: Theme.iconSize + 2; height: Theme.iconSize + 2
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: root.wifiConnected
                    ? root.wifiIcons[Math.max(0, Math.min(4, Math.round(root.wifiStrength / 25)))]
                    : root.wifiEnabled ? "󰤯" : "󰤭"
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                color: root.wifiNoInternet ? Theme.yellow
                     : root.wifiConnected  ? Theme.foreground
                     : Qt.alpha(Theme.foreground, 0.4)
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
        }

        Item {
            width: Theme.iconSize + 2; height: Theme.iconSize + 2
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: root.btConnected.length > 0 ? "󰂱" : root.btEnabled ? "󰂯" : "󰂲"
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                color: root.btEnabled ? Theme.foreground : Qt.alpha(Theme.foreground, 0.4)
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
        }

        Item {
            visible: root.volSink !== null
            width: Theme.iconSize + 2; height: Theme.iconSize + 2
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: root.muted         ? "󰝟"
                    : root.volume < 0.33 ? "󰕿"
                    : root.volume < 0.66 ? "󰖀"
                    : "󰕾"
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
        }
    }

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: hitArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onClicked: qsPopup.toggle()
    }

    // ── WiFi processes ────────────────────────────────────────────────────
    Process {
        id: wifiProc
        command: ["sh", "-c",
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -n1; " +
            "echo '@@'; nmcli -t -f CONNECTIVITY general 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@")
                const line  = (parts[0] ?? "").trim()
                if (line === "") {
                    root.wifiConnected = false; root.wifiStrength = 0; root.ssid = ""
                } else {
                    const f = line.split(":")
                    root.wifiConnected = true
                    root.wifiStrength  = parseInt(f[1]) || 0
                    root.ssid          = f.slice(2).join(":").replace(/\\:/g, ":")
                }
                root.wifiConnectivity = (parts[1] ?? "unknown").trim() || "unknown"
            }
        }
    }

    Process {
        id: radioProc
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
                if (root.wifiEnabled) wifiProc.running = true
            }
        }
    }

    Process {
        id: wifiToggleProc
        stdout: StdioCollector {}
        onExited: radioProc.running = true
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { radioProc.running = true; wifiProc.running = true }
    }

    // ── Popups ────────────────────────────────────────────────────────────
    QuickSettingsPopup {
        id: qsPopup
        anchorItem: root

        wifiEnabled:    root.wifiEnabled
        wifiConnected:  root.wifiConnected
        wifiStrength:   root.wifiStrength
        ssid:           root.ssid
        wifiNoInternet: root.wifiNoInternet

        onWifiToggled: {
            wifiToggleProc.command = ["nmcli", "radio", "wifi",
                root.wifiEnabled ? "off" : "on"]
            wifiToggleProc.running = true
        }

        // Dismiss QS panel then open the detail popup immediately — the exit
        // and enter spring animations overlap naturally from the same anchor.
        onWifiDrillDown:   { qsPopup.shown = false; wifiPopup.shown   = true }
        onBtDrillDown:     { qsPopup.shown = false; btPopup.shown     = true }
        onVolumeDrillDown: { qsPopup.shown = false; audioOutPopup.shown = true }
        onMicDrillDown:    { qsPopup.shown = false; audioInPopup.shown  = true }
    }

    WifiPopup {
        id: wifiPopup
        anchorItem: root
        onNetworkChanged: wifiProc.running = true
        onEscaped: { wifiPopup.shown = false; qsPopup.shown = true }
    }

    BluetoothPopup {
        id: btPopup
        anchorItem: root
        onEscaped: { btPopup.shown = false; qsPopup.shown = true }
    }

    AudioOutputPopup {
        id: audioOutPopup
        anchorItem: root
        onEscaped: { audioOutPopup.shown = false; qsPopup.shown = true }
    }

    AudioInputPopup {
        id: audioInPopup
        anchorItem: root
        onEscaped: { audioInPopup.shown = false; qsPopup.shown = true }
    }
}
