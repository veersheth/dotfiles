import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Battery level. Flashes red when critical; hover for time remaining,
// click for the power profile popup.
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
    readonly property bool perfMode: PowerProfiles.profile === PowerProfile.Performance

    // hide entirely on desktops with no battery
    visible: battery !== null && battery.isLaptopBattery

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    // performance mode orange backdrop
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Qt.alpha("#c60c0c", 0.82)
        opacity: root.perfMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
    }

    // green backdrop when charging
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Qt.alpha(Theme.green, 0.65)
        opacity: root.charging ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
    }

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
        onClicked: { tip.hide(); powerMenu.toggle() }
    }

    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14
        Text {
            id: tipText
            anchors.centerIn: parent
            text: {
                const pct = `${Math.round(root.percent)}%`
                if (root.critical)          return `${pct} · Critical`
                if (root.percent >= 99 && root.charging) return "Fully charged"
                if (root.charging)          return `${pct} · Charging`
                if (root.perfMode)          return `${pct} · Performance mode`
                return `${pct} · On battery`
            }
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    PowerProfilePopup {
        id: powerMenu
        anchorItem: root
    }
}
