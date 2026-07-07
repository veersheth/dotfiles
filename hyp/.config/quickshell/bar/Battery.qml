import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.bar.popups

// Battery level. Flashes red when critical; click for the power profile popup.
Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property real percent: (battery?.percentage ?? 0) * 100
    readonly property bool charging:
        battery !== null &&
        (battery.state === UPowerDeviceState.Charging ||
         battery.state === UPowerDeviceState.FullyCharged ||
         battery.state === UPowerDeviceState.PendingCharge)
    readonly property bool critical: !charging && percent < 10

    // hide entirely on desktops with no battery
    visible: battery !== null && battery.isLaptopBattery

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.pillHeight

    // flashing red backdrop when critical
    Rectangle {
        id: flash
        anchors.fill: parent
        radius: height / 2
        color: Theme.red
        opacity: 0
    }

    SequentialAnimation {
        running: root.critical
        loops: Animation.Infinite
        onStopped: flash.opacity = 0
        NumberAnimation { target: flash; property: "opacity"; to: 0.9;  duration: 450; easing.type: Easing.InOutQuad }
        NumberAnimation { target: flash; property: "opacity"; to: 0.15; duration: 450; easing.type: Easing.InOutQuad }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (root.charging) return "󰂄";
                const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
                const idx = Math.min(9, Math.max(0, Math.floor(root.percent / 10)));
                return icons[idx];
            }
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize
            color: Theme.foreground
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: `${Math.round(root.percent)}%`
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: powerMenu.toggle()
    }

    PowerProfilePopup {
        id: powerMenu
        anchorItem: root
    }
}
