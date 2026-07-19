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

    // ── Charging glow ──────────────────────────────────────────────────
    Rectangle {
        id: chargeGlow
        anchors.fill: parent; radius: height / 2
        color: Theme.blue
        opacity: 0
    }

    // Gentle breathing while charging; started programmatically below.
    SequentialAnimation {
        id: chargingBreath
        loops: Animation.Infinite
        NumberAnimation { target: chargeGlow; property: "opacity"; to: 0.22; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { target: chargeGlow; property: "opacity"; to: 0.06; duration: 900; easing.type: Easing.InOutSine }
    }

    // Bright flash on plug-in, fades into the breathing level.
    SequentialAnimation {
        id: chargeConnectAnim
        NumberAnimation { target: chargeGlow; property: "opacity"; to: 0.65; duration: 130; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 80 }
        NumberAnimation { target: chargeGlow; property: "opacity"; to: 0.10; duration: 550; easing.type: Easing.InCubic }
        onFinished: if (root.charging) chargingBreath.restart()
    }

    // Smooth fade out when unplugged.
    NumberAnimation {
        id: chargeGlowOut
        target: chargeGlow; property: "opacity"
        to: 0; duration: 400; easing.type: Easing.InCubic
    }

    // Suppress the plug-in flash during startup while UPower initialises.
    property bool _chargingReady: false
    Timer {
        interval: 1500; running: true
        onTriggered: {
            root._chargingReady = true
            // Charger was already connected at startup — begin breathing quietly.
            if (root.charging) chargingBreath.restart()
        }
    }

    onChargingChanged: {
        if (charging) {
            chargeGlowOut.stop()
            if (_chargingReady) {
                chargingBreath.stop()
                chargeConnectAnim.restart()
            } else {
                chargingBreath.restart()
            }
        } else {
            chargeConnectAnim.stop()
            chargingBreath.stop()
            chargeGlowOut.restart()
        }
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
        onClicked: powerMenu.toggle()
    }

    PowerProfilePopup {
        id: powerMenu
        anchorItem: root
    }
}
