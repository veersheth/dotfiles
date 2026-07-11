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

    property var rawNets: []        // scan results before the saved-profile join
    property var savedNames: []     // saved wifi connection profiles
    property var networks: []       // { ssid, signal, secured, inUse, known }
    property string connectivity: "unknown"
    property string expandedSsid: ""    // network with the password field open
    property string busySsid: ""        // network currently connecting
    property string error: ""

    // set per attempt so a failed first-time connect can clean up the
    // half-created profile nmcli leaves behind
    property string attemptSsid: ""
    property bool attemptNew: false

    readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    readonly property string statusText: {
        if (!networks.some(n => n.inUse)) return "Not connected";
        if (connectivity === "portal") return "Captive portal — sign-in required";
        if (connectivity === "limited" || connectivity === "none") return "Connected, no internet";
        return "Connected";
    }
    readonly property bool noInternet:
        connectivity === "none" || connectivity === "limited" || connectivity === "portal"

    contentWidth: 360
    contentHeight: col.implicitHeight + 32

    onShownChanged: {
        if (shown) {
            error = "";
            expandedSsid = "";
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
            if (ssid === "") continue;   // hidden networks
            const sec = f[2].trim();
            const net = {
                ssid: ssid,
                signal: parseInt(f[1]) || 0,
                secured: sec !== "" && sec !== "--",
                inUse: f[0] === "*",
            };
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
                root.savedNames = text.trim().split("\n")
                    .filter(s => s !== "")
                    .map(s => s.replace(/\\:/g, ":"));
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
                // a failed first-time attempt leaves a broken profile that
                // would shadow the password prompt on retry — drop it
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
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 2
            spacing: 8

            ColumnLayout {
                spacing: 1

                Text {
                    text: "Wi-Fi"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    color: Theme.foreground
                }
                Text {
                    text: root.statusText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    color: root.noInternet && root.networks.some(n => n.inUse)
                        ? Theme.yellow : Qt.alpha(Theme.foreground, 0.55)
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: 15
                color: settingsMouse.containsMouse ? Theme.hover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.family: Theme.nerdFont
                    font.pixelSize: Theme.iconSize
                    color: Qt.alpha(Theme.foreground, 0.6)
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["hypr-settings", "--wifi"]);
                        root.close();
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: 15
                color: rescanMouse.containsMouse ? Theme.hover : "transparent"

                Text {
                    id: rescanIcon
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.nerdFont
                    font.pixelSize: Theme.iconSize
                    color: Qt.alpha(Theme.foreground, rescanProc.running ? 0.9 : 0.6)
                }
                RotationAnimation {
                    target: rescanIcon; property: "rotation"
                    from: 0; to: 360; duration: 900
                    loops: Animation.Infinite
                    running: rescanProc.running
                    onStopped: rescanIcon.rotation = 0
                }

                MouseArea {
                    id: rescanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (!rescanProc.running) rescanProc.running = true
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.preferredHeight: Math.min(netCol.implicitHeight, 400)
            contentHeight: netCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: netCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.networks

                    delegate: Column {
                        id: netItem

                        required property var modelData

                        width: netCol.width
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 10
                            color: netItem.modelData.inUse ? Qt.alpha(Theme.blue, 0.18)
                                 : netMouse.containsMouse ? Theme.hover
                                 : "transparent"

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                Text {
                                    text: root.icons[Math.max(0, Math.min(4, Math.round(netItem.modelData.signal / 25)))]
                                    font.family: Theme.nerdFont
                                    font.pixelSize: Theme.iconSize
                                    color: netItem.modelData.inUse ? Theme.blue : Theme.foreground
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: netItem.modelData.ssid
                                    elide: Text.ElideRight
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                    font.weight: netItem.modelData.inUse ? Font.DemiBold : Font.Medium
                                    color: Theme.foreground
                                }
                                Text {
                                    visible: root.busySsid === netItem.modelData.ssid
                                    text: "connecting…"
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 3
                                    color: Qt.alpha(Theme.foreground, 0.55)
                                }
                                Text {
                                    visible: netItem.modelData.secured
                                    text: "󰌾"
                                    font.family: Theme.nerdFont
                                    font.pixelSize: Theme.iconSize - 2
                                    color: Qt.alpha(Theme.foreground, 0.5)
                                }
                                Text {
                                    visible: netItem.modelData.inUse
                                    text: "󰄬"
                                    font.family: Theme.nerdFont
                                    font.pixelSize: Theme.iconSize - 2
                                    color: Theme.blue
                                }
                            }

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
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

                        // inline password prompt for new secured networks
                        Rectangle {
                            visible: root.expandedSsid === netItem.modelData.ssid
                            width: parent.width - 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 34
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            onVisibleChanged: {
                                pwInput.text = "";
                                if (visible) pwInput.forceActiveFocus();
                            }

                            TextInput {
                                id: pwInput
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                passwordCharacter: "●"
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                color: Theme.foreground
                                clip: true
                                onAccepted: if (text !== "") root.connectTo(netItem.modelData, text)
                                Keys.onEscapePressed: root.expandedSsid = ""
                            }

                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                visible: pwInput.text === ""
                                text: "password — Enter to connect"
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                color: Qt.alpha(Theme.foreground, 0.35)
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.networks.length === 0
            Layout.leftMargin: 8
            Layout.topMargin: 2
            text: rescanProc.running ? "Scanning…" : "No networks found"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            color: Qt.alpha(Theme.foreground, 0.5)
        }

        Text {
            visible: root.error !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: root.error
            wrapMode: Text.Wrap
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            color: Qt.alpha(Theme.red, 0.9)
        }
    }
}
