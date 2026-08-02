import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Bluetooth adapter/connection state + connected device name.
// Click to open the device popup; settings button inside handles hypr-settings.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices:
        enabled ? Bluetooth.devices.values.filter(d => d.connected) : []
    readonly property bool connected: connectedDevices.length > 0

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: Math.max(row.implicitWidth + 10, 33)
    implicitHeight: Theme.pillHeight

    Row {
        id: row
        spacing: 7
        anchors.centerIn: parent

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

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: hitArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onEntered: tip.show(root)
        onExited:  tip.hide()
        onClicked: { tip.hide(); btPopup.toggle() }
    }

    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14

        Text {
            id: tipText
            anchors.centerIn: parent
            text: !root.enabled ? "Bluetooth off"
                : root.connected ? root.connectedDevices.map(d => d.name).join(" · ")
                : "No devices connected"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    BluetoothPopup {
        id: btPopup
        anchorItem: root
    }
}
