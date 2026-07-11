import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.common

// Bluetooth adapter/connection state + connected device name.
// Click to open hypr-settings.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices:
        enabled ? Bluetooth.devices.values.filter(d => d.connected) : []
    readonly property bool connected: connectedDevices.length > 0

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 7
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.connected ? "󰂱" : root.enabled ? "󰂯" : "󰂲"
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize
            color: root.enabled ? Theme.foreground : Qt.alpha(Theme.foreground, 0.4)

            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.connected
            text: root.connectedDevices.length > 1
                ? `${root.connectedDevices[0]?.name ?? ""} +${root.connectedDevices.length - 1}`
                : (root.connectedDevices[0]?.name ?? "")
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Qt.alpha(Theme.foreground, 0.85)
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        onClicked: Quickshell.execDetached(["hypr-settings", "--bluetooth"])
    }
}
