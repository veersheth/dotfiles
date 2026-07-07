import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.common

// Bluetooth adapter/connection state. Click to open hypr-settings.
Text {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool connected: {
        if (!enabled) return false;
        const devices = Bluetooth.devices.values;
        for (const d of devices)
            if (d.connected) return true;
        return false;
    }

    Layout.alignment: Qt.AlignVCenter
    text: connected ? "󰂱" : enabled ? "󰂯" : "󰂲"
    font.family: Theme.nerdFont
    font.pixelSize: Theme.iconSize
    color: enabled ? Theme.foreground : Qt.alpha(Theme.foreground, 0.4)

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        onClicked: Quickshell.execDetached(["hypr-settings", "--bluetooth"])
    }
}
