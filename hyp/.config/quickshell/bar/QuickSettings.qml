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
            id: wifiZone
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
            id: btZone
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
            id: volZone
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

    property int shownZone: 0

    function tipZone() {
        if (wifiZone.contains(wifiZone.mapFromItem(hitArea, hitArea.mouseX, hitArea.mouseY))) return 1
        if (btZone.contains(btZone.mapFromItem(hitArea, hitArea.mouseX, hitArea.mouseY)))   return 2
        if (volZone.visible && volZone.contains(volZone.mapFromItem(hitArea, hitArea.mouseX, hitArea.mouseY))) return 3
        return 0
    }

    function updateTip() {
        const z = root.tipZone()
        if (z > 0) { root.shownZone = z; tip.show(root) }
        else tip.hide()
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onEntered:         root.updateTip()
        onExited:          tip.hide()
        onPositionChanged: root.updateTip()
        onClicked: {
            tip.hide()
            if (!qsLoader.active) {
                qsLoader.active = true
            } else {
                qsLoader.item.toggle()
            }
        }
    }

    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14
        Text {
            id: tipText
            anchors.centerIn: parent
            text: {
                const z = root.shownZone
                if (z === 1) return root.wifiNoInternet
                    ? `${root.ssid} · ${root.wifiConnectivity === "portal" ? "captive portal" : "no internet"}`
                    : root.wifiConnected ? `${root.ssid} · ${root.wifiStrength}%` : "Not connected"
                if (z === 2) return !root.btEnabled ? "Bluetooth off"
                    : root.btConnected.length > 0 ? root.btConnected.map(d => d.name).join(" · ")
                    : "No devices connected"
                if (z === 3) return root.muted
                    ? `Muted · ${Math.round(root.volume * 100)}%`
                    : `${Math.round(root.volume * 100)}%`
                return ""
            }
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
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
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { radioProc.running = true; wifiProc.running = true }
    }

    // ── Popups (lazy-loaded on first open) ───────────────────────────────
    Loader {
        id: qsLoader
        active: false
        sourceComponent: Component { QuickSettingsPopup {} }
        onLoaded: {
            item.anchorItem    = root
            item.wifiEnabled   = Qt.binding(() => root.wifiEnabled)
            item.wifiConnected = Qt.binding(() => root.wifiConnected)
            item.wifiStrength  = Qt.binding(() => root.wifiStrength)
            item.ssid          = Qt.binding(() => root.ssid)
            item.wifiNoInternet = Qt.binding(() => root.wifiNoInternet)
            item.wifiToggled.connect(() => {
                wifiToggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]
                wifiToggleProc.running = true
            })
            item.wifiDrillDown.connect(() => {
                item.shown = false
                wifiLoader.active = true
                wifiLoader.item.shown = true
            })
            item.btDrillDown.connect(() => {
                item.shown = false
                btLoader.active = true
                btLoader.item.shown = true
            })
            item.volumeDrillDown.connect(() => {
                item.shown = false
                audioOutLoader.active = true
                audioOutLoader.item.shown = true
            })
            item.micDrillDown.connect(() => {
                item.shown = false
                audioInLoader.active = true
                audioInLoader.item.shown = true
            })
            item.toggle()
        }
    }

    Loader {
        id: wifiLoader
        active: false
        sourceComponent: Component { WifiPopup {} }
        onLoaded: {
            item.anchorItem = root
            item.networkChanged.connect(() => wifiProc.running = true)
            item.escaped.connect(() => { item.shown = false; qsLoader.item.shown = true })
        }
    }

    Loader {
        id: btLoader
        active: false
        sourceComponent: Component { BluetoothPopup {} }
        onLoaded: {
            item.anchorItem = root
            item.escaped.connect(() => { item.shown = false; qsLoader.item.shown = true })
        }
    }

    Loader {
        id: audioOutLoader
        active: false
        sourceComponent: Component { AudioOutputPopup {} }
        onLoaded: {
            item.anchorItem = root
            item.escaped.connect(() => { item.shown = false; qsLoader.item.shown = true })
        }
    }

    Loader {
        id: audioInLoader
        active: false
        sourceComponent: Component { AudioInputPopup {} }
        onLoaded: {
            item.anchorItem = root
            item.escaped.connect(() => { item.shown = false; qsLoader.item.shown = true })
        }
    }
}
