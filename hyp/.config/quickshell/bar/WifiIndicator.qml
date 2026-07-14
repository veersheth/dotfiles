import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Wifi via nmcli: signal icon + SSID, tinted yellow when the link is up but
// connectivity checks fail (no internet / captive portal). Click for the
// network picker popup.
Item {
    id: root

    property bool connected: false
    property int strength: 0
    property string ssid: ""
    // NetworkManager connectivity: full | limited | portal | none | unknown
    property string connectivity: "unknown"
    readonly property bool noInternet:
        connected && (connectivity === "none" || connectivity === "limited" || connectivity === "portal")

    readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    Row {
        id: row
        spacing: 7
        anchors.centerIn: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.connected
                ? root.icons[Math.max(0, Math.min(4, Math.round(root.strength / 25)))]
                : "󰤭"
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize
            color: root.noInternet ? Theme.yellow
                 : root.connected ? Theme.foreground
                 : Qt.alpha(Theme.foreground, 0.4)

            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.connected && root.ssid !== ""
            text: root.noInternet
                ? `${root.ssid} · ${root.connectivity === "portal" ? "captive portal" : "no internet"}`
                : root.ssid
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: root.noInternet ? Theme.yellow : Qt.alpha(Theme.foreground, 0.85)

            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["hypr-settings", "--wifi"]);
            else
                networks.toggle();
        }
    }

    WifiPopup {
        id: networks
        anchorItem: root
        onNetworkChanged: wifiProc.running = true
    }

    Process {
        id: wifiProc
        command: ["sh", "-c",
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -n1; " +
            "echo '@@'; nmcli -t -f CONNECTIVITY general 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@");
                const line = (parts[0] ?? "").trim();
                if (line === "") {
                    root.connected = false;
                    root.strength = 0;
                    root.ssid = "";
                } else {
                    const f = line.split(":");
                    root.connected = true;
                    root.strength = parseInt(f[1]) || 0;
                    root.ssid = f.slice(2).join(":").replace(/\\:/g, ":");
                }
                root.connectivity = (parts[1] ?? "unknown").trim() || "unknown";
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
