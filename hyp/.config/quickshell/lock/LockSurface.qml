import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import qs.common
import qs.components
import qs.wallpaper

Item {
    id: root
    required property var ctx

    Image {
        id: wall
        anchors.fill: parent
        source: WallpaperService.current.length > 0 ? "file://" + WallpaperService.current : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    opacity: 0
    Component.onCompleted: {
        opacity = 1
        input.forceActiveFocus()
        ctx.begin()
    }
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // ── Battery ───────────────────────────────────────────────────────────
    Row {
        anchors { top: parent.top; right: parent.right; margins: 24 }
        spacing: 6
        visible: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery

        readonly property var   bat:      UPower.displayDevice
        readonly property real  pct:      (bat?.percentage ?? 0) * 100
        readonly property bool  charging: bat !== null && (
            bat.state === UPowerDeviceState.Charging ||
            bat.state === UPowerDeviceState.FullyCharged ||
            bat.state === UPowerDeviceState.PendingCharge)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (parent.charging) return "󰂄"
                const icons = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
                return icons[Math.min(9, Math.max(0, Math.floor(parent.pct / 10)))]
            }
            font.family: Theme.nerdFont
            font.pixelSize: 15
            color: Qt.rgba(1, 1, 1, 0.65)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(parent.pct)}%`
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Qt.rgba(1, 1, 1, 0.65)
        }
    }

    // ── Media card (right) ────────────────────────────────────────────────
    Item {
        id: mediaHost

        property var _lastPlayer: null
        readonly property var player: {
            const players = Mpris.players.values
            if (players.length === 0) return null
            for (const p of players)
                if (p.playbackState === MprisPlaybackState.Playing) {
                    mediaHost._lastPlayer = p; return p
                }
            if (mediaHost._lastPlayer !== null)
                for (const p of players)
                    if (p === mediaHost._lastPlayer) return p
            mediaHost._lastPlayer = players[0]
            return players[0]
        }

        anchors {
            right: parent.right
            rightMargin: parent.width * 0.07
            verticalCenter: parent.verticalCenter
        }
        width: 300
        height: mediaCard.implicitHeight

        opacity: player !== null ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }
        visible: opacity > 0

        Rectangle {
            anchors.fill: parent
            radius: Theme.popupRadius
            color: Qt.rgba(0, 0, 0, 0.35)
            border.width: Theme.borderWidth
            border.color: Theme.border
        }

        MediaCard {
            id: mediaCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            player: mediaHost.player
            active: mediaHost.visible
        }
    }

    // ── Center column ─────────────────────────────────────────────────────
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        anchors.centerIn: parent
        spacing: 0

        // Time + AM/PM
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Text {
                id: timeText
                text: Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")[0]
                font.family: Theme.nerdFont
                font.pixelSize: 100
                font.weight: Font.Bold
                color: "white"
            }
            Text {
                text: Qt.formatDateTime(clock.date, "AP")
                font.family: Theme.font
                font.pixelSize: 20
                font.weight: Font.Light
                color: Qt.rgba(1, 1, 1, 0.5)
                anchors.bottom: timeText.bottom
                bottomPadding: 14
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            font.family: Theme.font
            font.pixelSize: 16
            color: Qt.rgba(1, 1, 1, 0.55)
        }

        Item { width: 1; height: 52 }

        // ── Password input + lock icon ─────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Rectangle {
                id: inputBox
                width: 260
                height: 42
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                border.color: root.ctx.status === "Incorrect password"
                    ? Qt.rgba(1, 0.3, 0.3, 0.75)
                    : Qt.rgba(1, 1, 1, 0.22)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                transform: Translate { id: shakeT }

                TextInput {
                    id: input
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: "white"
                    enabled: !root.ctx.authenticating && !root.ctx.succeeded
                    clip: true
                    onTextChanged: root.ctx.currentText = text
                    onAccepted:    root.ctx.submit()

                    Connections {
                        target: root.ctx
                        function onCurrentTextChanged() {
                            if (root.ctx.currentText === "") input.text = ""
                        }
                        function onFailed() { shake.restart() }
                    }
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 40 }
                    NumberAnimation { target: shakeT; property: "x"; to:  10; duration: 40 }
                    NumberAnimation { target: shakeT; property: "x"; to:  -6; duration: 40 }
                    NumberAnimation { target: shakeT; property: "x"; to:   4; duration: 40 }
                    NumberAnimation { target: shakeT; property: "x"; to:   0; duration: 40 }
                }
            }

            FingerprintIcon {
                id: fpIcon
                width: 32; height: 32
                anchors.verticalCenter: parent.verticalCenter
                scanning:  !root.ctx.authenticating && !root.ctx.succeeded
                iconColor: root.ctx.status === "Incorrect password"
                    ? Theme.red : Qt.rgba(1, 1, 1, 0.85)

                Connections {
                    target: root.ctx
                    function onSucceededChanged() {
                        if (root.ctx.succeeded) {
                            fpIcon.revertAnim.stop()
                            fpIcon.unlockAnim.restart()
                        } else {
                            fpIcon.unlockAnim.stop()
                            fpIcon.morph = 0
                            fpIcon.scale = 1
                        }
                    }
                    function onFailed() {
                        fpIcon.unlockAnim.stop()
                        fpIcon.revertAnim.restart()
                        shake.restart()
                    }
                }
            }
        }
    }

    // ── Status message ────────────────────────────────────────────────────
    Text {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 40 }
        text: root.ctx.authenticating ? "Authenticating…"
            : root.ctx.status !== ""   ? root.ctx.status
            : ""
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        color: root.ctx.status === "Incorrect password"
            ? Qt.rgba(1, 0.4, 0.4, 0.85)
            : Qt.rgba(1, 1, 1, 0.4)
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
