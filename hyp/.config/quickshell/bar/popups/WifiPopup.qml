import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Wifi network picker backed by nmcli. Shows cached scan results instantly,
// rescans in the background. Click a network to connect — known and open
// networks connect directly, new secured ones get an inline password prompt.
BarPopup {
    id: root

    // fired after a successful connect so the bar indicator can refresh
    signal networkChanged()

    property var rawNets: []
    property var savedNames: []
    property var networks: []
    property string connectivity: "unknown"
    property string expandedSsid: ""
    property string busySsid: ""
    property string error: ""
    property string attemptSsid: ""
    property bool attemptNew: false
    property bool wifiEnabled: true

    readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    readonly property string statusText: {
        if (!wifiEnabled) return "Off";
        if (!networks.some(n => n.inUse)) return "Not connected";
        if (connectivity === "portal") return "Captive portal — sign-in required";
        if (connectivity === "limited" || connectivity === "none") return "Connected, no internet";
        return "Connected";
    }
    readonly property bool noInternet:
        connectivity === "none" || connectivity === "limited" || connectivity === "portal"

    contentWidth: 360
    contentHeight: 380

    onShownChanged: {
        if (shown) {
            error = "";
            expandedSsid = "";
            radioProc.running = true;
            refresh();
            rescanProc.running = true;
        }
    }

    function refresh() {
        statusProc.running = true;
        savedProc.running = true;
        scanProc.running = true;
    }

    function rebuild() {
        const nets = rawNets.map(n => Object.assign({}, n, { known: savedNames.includes(n.ssid) }));
        nets.sort((a, b) => (b.inUse - a.inUse) || (b.known - a.known) || (b.signal - a.signal));
        networks = nets;
    }

    function parseScan(text) {
        const seen = {};
        for (const line of text.trim().split("\n")) {
            const f = line.split(":");
            if (f.length < 4) continue;
            const ssid = f.slice(3).join(":").replace(/\\:/g, ":");
            if (ssid === "") continue;
            const sec = f[2].trim();
            const net = { ssid, signal: parseInt(f[1]) || 0, secured: sec !== "" && sec !== "--", inUse: f[0] === "*" };
            const prev = seen[ssid];
            if (!prev || (net.inUse && !prev.inUse) || (!prev.inUse && net.signal > prev.signal))
                seen[ssid] = net;
        }
        rawNets = Object.values(seen);
        rebuild();
    }

    function connectTo(net, password) {
        if (busySsid !== "") return;
        error = "";
        busySsid = net.ssid;
        attemptSsid = net.ssid;
        attemptNew = !net.known;
        if (password !== "")
            connectProc.command = ["nmcli", "dev", "wifi", "connect", net.ssid, "password", password];
        else if (net.known)
            connectProc.command = ["nmcli", "con", "up", "id", net.ssid];
        else
            connectProc.command = ["nmcli", "dev", "wifi", "connect", net.ssid];
        connectProc.running = true;
    }

    // ── nmcli plumbing ─────────────────────────────────────────────────
    Process {
        id: radioProc
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }
    Process {
        id: toggleProc
        stdout: StdioCollector {}
        onExited: { radioProc.running = true; if (root.wifiEnabled) root.refresh() }
    }
    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.parseScan(text) }
    }
    Process {
        id: rescanProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan yes 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.parseScan(text) }
    }
    Process {
        id: savedProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE connection show 2>/dev/null | sed -n 's/:802-11-wireless$//p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNames = text.trim().split("\n").filter(s => s !== "").map(s => s.replace(/\\:/g, ":"));
                root.rebuild();
            }
        }
    }
    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli -t -f CONNECTIVITY general 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.connectivity = text.trim() || "unknown" }
    }
    Process {
        id: connectProc
        stdout: StdioCollector {}
        stderr: StdioCollector { id: connErr }
        onExited: (code, status) => {
            root.busySsid = "";
            if (code === 0) {
                root.expandedSsid = "";
                root.refresh();
                root.networkChanged();
            } else {
                const msg = connErr.text.trim().replace(/^Error:\s*/, "");
                root.error = msg !== "" ? msg : "Failed to connect";
                if (root.attemptNew && root.attemptSsid !== "") {
                    cleanupProc.command = ["nmcli", "connection", "delete", "id", root.attemptSsid];
                    cleanupProc.running = true;
                }
            }
        }
    }
    Process {
        id: cleanupProc
        onExited: savedProc.running = true
    }

    // ── UI ─────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 16 }
        spacing: 6

        // ── Header: Wi-Fi  subtitle  [⚙] [↺] [toggle] ─────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.rightMargin: 2
            spacing: 8

            ColumnLayout {
                spacing: 1
                Text {
                    text: "Wi-Fi"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
                    color: Theme.foreground
                }
                Text {
                    text: root.statusText
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    color: root.noInternet && root.networks.some(n => n.inUse)
                        ? Theme.yellow : Qt.alpha(Theme.foreground, 0.55)
                }
            }

            Item { Layout.fillWidth: true }

            // settings
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: settingsMo.containsMouse ? Theme.hover : "transparent"
                Text { anchors.centerIn: parent; text: "󰒓"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Qt.alpha(Theme.foreground, 0.6) }
                MouseArea { id: settingsMo; anchors.fill: parent; hoverEnabled: true; onClicked: { Quickshell.execDetached(["hypr-settings", "--wifi"]); root.close() } }
            }

            // rescan
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: rescanMo.containsMouse ? Theme.hover : "transparent"
                Text {
                    id: rescanIcon; anchors.centerIn: parent; text: "󰑐"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                    color: Qt.alpha(Theme.foreground, rescanProc.running ? 0.9 : 0.6)
                }
                RotationAnimation { target: rescanIcon; property: "rotation"; from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: rescanProc.running; onStopped: rescanIcon.rotation = 0 }
                MouseArea { id: rescanMo; anchors.fill: parent; hoverEnabled: true; onClicked: if (!rescanProc.running) rescanProc.running = true }
            }

            // wifi radio toggle
            PopupToggle {
                Layout.alignment: Qt.AlignVCenter
                checked: root.wifiEnabled
                onToggled: {
                    toggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
                    toggleProc.running = true;
                }
            }
        }

        // network list
        Flickable {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.fillHeight: true
            contentHeight: netCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: netCol
                width: parent.width
                spacing: 2

                Text {
                    visible: root.wifiEnabled && root.networks.length === 0
                    width: parent.width
                    leftPadding: 8; topPadding: 2
                    text: rescanProc.running ? "Scanning…" : "No networks found"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.foreground, 0.5)
                }

                Text {
                    visible: root.error !== ""
                    width: parent.width
                    leftPadding: 8
                    text: root.error; wrapMode: Text.Wrap
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.red, 0.9)
                }

                Repeater {
                    model: root.networks

                    delegate: Column {
                        id: netItem
                        required property var modelData
                        width: netCol.width
                        spacing: 4

                        Rectangle {
                            width: parent.width; height: 38; radius: Theme.itemRadius
                            color: netItem.modelData.inUse ? Qt.alpha(Theme.blue, 0.18)
                                 : netMouse.containsMouse ? Theme.hover : "transparent"

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10
                                Text {
                                    text: root.icons[Math.max(0, Math.min(4, Math.round(netItem.modelData.signal / 25)))]
                                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                                    color: netItem.modelData.inUse ? Theme.blue : Theme.foreground
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: netItem.modelData.ssid; elide: Text.ElideRight
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize
                                    font.weight: netItem.modelData.inUse ? Font.DemiBold : Font.Medium
                                    color: Theme.foreground
                                }
                                Text {
                                    visible: root.busySsid === netItem.modelData.ssid
                                    text: "connecting…"
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                                    color: Qt.alpha(Theme.foreground, 0.55)
                                }
                                Text {
                                    visible: netItem.modelData.secured
                                    text: "󰌾"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                                    color: Qt.alpha(Theme.foreground, 0.5)
                                }
                                Text {
                                    visible: netItem.modelData.inUse
                                    text: "󰄬"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                                    color: Theme.blue
                                }
                            }

                            MouseArea {
                                id: netMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    const net = netItem.modelData;
                                    if (net.inUse || root.busySsid !== "") return;
                                    if (net.secured && !net.known) {
                                        root.expandedSsid = root.expandedSsid === net.ssid ? "" : net.ssid;
                                        root.error = "";
                                    } else {
                                        root.connectTo(net, "");
                                    }
                                }
                            }
                        }

                        // inline password prompt
                        Rectangle {
                            visible: root.expandedSsid === netItem.modelData.ssid
                            width: parent.width - 16; anchors.horizontalCenter: parent.horizontalCenter
                            height: 34; radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: Theme.borderWidth; border.color: Theme.border
                            onVisibleChanged: { pwInput.text = ""; if (visible) pwInput.forceActiveFocus() }
                            TextInput {
                                id: pwInput
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password; passwordCharacter: "●"
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                                color: Theme.foreground; clip: true
                                onAccepted: if (text !== "") root.connectTo(netItem.modelData, text)
                                Keys.onEscapePressed: root.expandedSsid = ""
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                visible: pwInput.text === ""
                                text: "password — Enter to connect"
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                                color: Qt.alpha(Theme.foreground, 0.35)
                            }
                        }
                    }
                }
            }
        }

    }
}
