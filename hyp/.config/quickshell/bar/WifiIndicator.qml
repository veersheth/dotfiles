import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common

// Wifi signal strength via nmcli. Click to open hypr-settings.
Text {
    id: root

    property bool connected: false
    property int strength: 0
    property string ssid: ""

    readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    Layout.alignment: Qt.AlignVCenter
    text: connected
        ? icons[Math.max(0, Math.min(4, Math.round(strength / 25)))]
        : "󰤭"
    font.family: Theme.nerdFont
    font.pixelSize: Theme.iconSize
    color: connected ? Theme.foreground : Qt.alpha(Theme.foreground, 0.4)

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        onClicked: Quickshell.execDetached(["hypr-settings", "--wifi"])
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (line === "") {
                    root.connected = false;
                    root.strength = 0;
                    root.ssid = "";
                } else {
                    const parts = line.split(":");
                    root.connected = true;
                    root.strength = parseInt(parts[1]) || 0;
                    root.ssid = parts.slice(2).join(":");
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }
}
