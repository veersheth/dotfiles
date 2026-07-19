import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Bluetooth panel. Header matches WifiPopup: title | settings | scan | toggle.
// Paired devices first, then a divider, then nearby discovered devices.
BarPopup {
    id: root

    readonly property var adapter:  Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    readonly property var pairedDevices:  Bluetooth.devices.values.filter(d => d.paired)
    readonly property var nearbyDevices:  Bluetooth.devices.values.filter(d => !d.paired).slice(0, 10)
    readonly property bool scanning: adapter?.discovering ?? false

    property string connectingAddress: ""

    signal escaped()
    onEscaped: close()

    contentWidth:  Theme.listWidth + 2 * contentPadding
    contentHeight: col.implicitHeight + 2 * contentPadding

    onShownChanged: {
        if (!shown) connectingAddress = "";
        if (shown && enabled) adapter.discovering = true;
    }

    // ── Device row component ────────────────────────────────────────────
    component DevRow: Rectangle {
        id: dev
        required property var modelData

        readonly property bool isConnected: modelData.connected
        readonly property bool isPaired:    modelData.paired
        readonly property bool isBusy: root.connectingAddress === modelData.address

        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.itemRadius
        color: devMo.containsMouse ? Theme.hover : "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10

            Text {
                text: {
                    const t = dev.modelData.type ?? "";
                    if (t === "headset" || t === "headphones") return "󰋋";
                    if (t === "keyboard")  return "󰌌";
                    if (t === "mouse")     return "󰍽";
                    if (t === "phone")     return "󰏲";
                    if (t === "speakers")  return "󰓃";
                    if (t === "gamepad")   return "󰊗";
                    return "󰂱";
                }
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                color: dev.isConnected ? Theme.blue : Qt.alpha(Theme.foreground, 0.55)
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: dev.modelData.name ?? dev.modelData.address
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                color: Theme.foreground
            }

            // battery percentage when reported
            Text {
                visible: (dev.modelData.battery ?? -1) >= 0
                text: `${dev.modelData.battery ?? 0}%`
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                color: Qt.alpha(Theme.foreground, 0.45)
            }

            // spinner while connecting, check when connected
            Text {
                id: statusGlyph
                visible: dev.isBusy || dev.isConnected
                text: dev.isBusy ? "󰑐" : "󰄬"
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                color: dev.isConnected ? Theme.blue : Qt.alpha(Theme.foreground, 0.5)
                RotationAnimation on rotation {
                    running: dev.isBusy; loops: Animation.Infinite
                    from: 0; to: 360; duration: 900
                }
                onVisibleChanged: if (!dev.isBusy) rotation = 0
            }
        }

        MouseArea {
            id: devMo; anchors.fill: parent; hoverEnabled: true
            enabled: !dev.isBusy
            onClicked: {
                if (dev.isConnected) {
                    dev.modelData.connected = false;
                } else {
                    root.connectingAddress = dev.modelData.address;
                    dev.modelData.connected = true;
                    connectTimeout.restart();
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.escaped()
    }

    // ── UI ──────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 4

        // ── Header: Bluetooth  [⚙] [↺] [toggle] ───────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4; Layout.rightMargin: 2
            Layout.bottomMargin: 4
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: btBackMo.containsMouse ? Theme.hover : "transparent"
                Text { anchors.centerIn: parent; text: "󰅁"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Qt.alpha(Theme.foreground, 0.7) }
                MouseArea { id: btBackMo; anchors.fill: parent; hoverEnabled: true; onClicked: root.escaped() }
            }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "Bluetooth"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
                    color: Theme.foreground
                }
                Text {
                    text: !root.enabled ? "Off"
                        : root.pairedDevices.filter(d => d.connected).length > 0
                            ? "Connected"
                            : "On"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    color: Qt.alpha(Theme.foreground, 0.55)
                }
            }

            Item { Layout.fillWidth: true }

            // settings
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: settingsMo.containsMouse ? Theme.hover : "transparent"
                Text { anchors.centerIn: parent; text: "󰒓"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Qt.alpha(Theme.foreground, 0.6) }
                MouseArea { id: settingsMo; anchors.fill: parent; hoverEnabled: true; onClicked: { Quickshell.execDetached(["hypr-settings", "--bluetooth"]); root.close() } }
            }

            // scan refresh
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: scanMo.containsMouse ? Theme.hover : "transparent"
                Text {
                    id: scanIcon; anchors.centerIn: parent; text: "󰑐"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                    color: Qt.alpha(Theme.foreground, root.scanning ? 0.9 : 0.6)
                }
                RotationAnimation { target: scanIcon; property: "rotation"; from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: root.scanning; onStopped: scanIcon.rotation = 0 }
                MouseArea { id: scanMo; anchors.fill: parent; hoverEnabled: true; enabled: root.enabled; onClicked: if (!root.scanning) root.adapter.discovering = true }
            }

            // adapter toggle
            PopupToggle {
                Layout.alignment: Qt.AlignVCenter
                checked: root.enabled
                onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        }

        // Scrollable device list
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(60, Math.min(devContent.implicitHeight + 8, 300))
            contentHeight: devContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            CommonList {
                id: devContent
                width: parent.width
                spacing: 4

                // ── Off state ───────────────────────────────────────────
                Text {
                    visible: !root.enabled
                    Layout.fillWidth: true; Layout.topMargin: 6; Layout.bottomMargin: 6
                    horizontalAlignment: Text.AlignHCenter
                    text: "Bluetooth is off"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    color: Qt.alpha(Theme.foreground, 0.45)
                }

                // ── Known / paired devices ──────────────────────────────
                Repeater {
                    model: root.enabled ? root.pairedDevices : []
                    delegate: DevRow {}
                }

                Text {
                    visible: root.enabled && root.pairedDevices.length === 0
                    Layout.leftMargin: 8; Layout.topMargin: 2; Layout.bottomMargin: 2
                    text: "No saved devices"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.foreground, 0.45)
                }

                // ── Divider + nearby section ────────────────────────────
                ColumnLayout {
                    visible: root.enabled
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        Layout.leftMargin: 8; Layout.rightMargin: 8

                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: Theme.borderWidth
                            color: Theme.border; opacity: 0.5
                        }
                        Text {
                            text: "Nearby"
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.DemiBold
                            color: Qt.alpha(Theme.foreground, 0.4)
                            leftPadding: 8; rightPadding: 8
                        }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: Theme.borderWidth
                            color: Theme.border; opacity: 0.5
                        }
                    }

                    Repeater {
                        model: root.nearbyDevices
                        delegate: DevRow {}
                    }

                    Text {
                        visible: root.nearbyDevices.length === 0
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        horizontalAlignment: Text.AlignHCenter
                        text: root.scanning ? "Scanning…" : "No devices nearby"
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        color: Qt.alpha(Theme.foreground, 0.4)
                    }
                }
            }
        }
    }

    Timer {
        id: connectTimeout; interval: 8000
        onTriggered: root.connectingAddress = ""
    }

    Connections {
        target: Bluetooth
        function onDevicesChanged() {
            const dev = Bluetooth.devices.values.find(d => d.address === root.connectingAddress);
            if (dev && (dev.connected || !dev.paired)) root.connectingAddress = "";
        }
    }
}
