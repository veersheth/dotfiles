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
        color: Qt.alpha("#d4783a", 0.22)
        opacity: root.perfMode ? 1 : 0
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
        onEntered: batTip.show(root)
        onExited:  batTip.hide()
        onClicked: {
            batTip.hide();
            powerMenu.toggle();
        }
    }

    PowerProfilePopup {
        id: powerMenu
        anchorItem: root
    }

    BarTooltip {
        id: batTip

        readonly property int secs: root.charging
            ? (root.battery?.timeToFull ?? 0)
            : (root.battery?.timeToEmpty ?? 0)

        function fmt(s) {
            const m = Math.round(s / 60);
            return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
        }

        contentWidth:  batTipText.implicitWidth + 28
        contentHeight: batTipText.implicitHeight + 16

        Text {
            id: batTipText
            anchors.centerIn: parent
            text: {
                if (root.battery?.state === UPowerDeviceState.FullyCharged)
                    return "Fully charged";
                if (batTip.secs <= 0)
                    return root.charging ? "Charging" : "On battery";
                return root.charging
                    ? `${batTip.fmt(batTip.secs)} until full`
                    : `${batTip.fmt(batTip.secs)} remaining`;
            }
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }
}
