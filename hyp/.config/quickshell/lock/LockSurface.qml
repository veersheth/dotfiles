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

            Item {
                id: padlock
                width: 36; height: 42

                property real shackle: 0
                property real morph:   0

                onShackleChanged: cv.requestPaint()
                onMorphChanged:   cv.requestPaint()

                Canvas {
                    id: cv
                    anchors.centerIn: parent
                    width: 36; height: 36

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.lineWidth = 3.2
                        ctx.lineCap  = "round"
                        ctx.lineJoin = "round"

                        const lockAlpha = Math.max(0, 1 - padlock.morph * 1.6)
                        if (lockAlpha > 0.01) {
                            ctx.globalAlpha = lockAlpha * 0.85
                            ctx.strokeStyle = "white"
                            const x = 8, y = 16, bw = 20, bh = 13, r = 3.5
                            ctx.beginPath()
                            ctx.moveTo(x + r, y)
                            ctx.lineTo(x + bw - r, y); ctx.arcTo(x + bw, y, x + bw, y + r, r)
                            ctx.lineTo(x + bw, y + bh - r); ctx.arcTo(x + bw, y + bh, x + bw - r, y + bh, r)
                            ctx.lineTo(x + r, y + bh); ctx.arcTo(x, y + bh, x, y + bh - r, r)
                            ctx.lineTo(x, y + r); ctx.arcTo(x, y, x + r, y, r)
                            ctx.closePath()
                            ctx.stroke()
                            ctx.save()
                            ctx.translate(12, 16)
                            ctx.rotate(-padlock.shackle * 1.0)
                            ctx.translate(-12, -16)
                            ctx.beginPath()
                            ctx.arc(18, 16, 6, Math.PI, 2 * Math.PI, false)
                            ctx.stroke()
                            ctx.restore()
                        }

                        if (padlock.morph > 0.01) {
                            const A = { x: 7,  y: 20 }
                            const B = { x: 14, y: 27 }
                            const C = { x: 29, y: 10 }
                            const l1 = Math.hypot(B.x - A.x, B.y - A.y)
                            const l2 = Math.hypot(C.x - B.x, C.y - B.y)
                            const p  = padlock.morph * (l1 + l2)
                            ctx.globalAlpha = Math.min(1, padlock.morph * 2)
                            ctx.strokeStyle = Theme.green
                            ctx.beginPath()
                            ctx.moveTo(A.x, A.y)
                            if (p <= l1) {
                                const k = p / l1
                                ctx.lineTo(A.x + (B.x - A.x) * k, A.y + (B.y - A.y) * k)
                            } else {
                                ctx.lineTo(B.x, B.y)
                                const k = (p - l1) / l2
                                ctx.lineTo(B.x + (C.x - B.x) * k, B.y + (C.y - B.y) * k)
                            }
                            ctx.stroke()
                        }
                    }
                }

                SequentialAnimation {
                    id: unlockAnim
                    NumberAnimation { target: padlock; property: "shackle"; to: 1; duration: 180; easing.type: Easing.InOutQuad }
                    ParallelAnimation {
                        NumberAnimation { target: padlock; property: "morph"; to: 1; duration: 400; easing.type: Easing.InOutCubic }
                        SequentialAnimation {
                            NumberAnimation { target: padlock; property: "scale"; to: 1.2; duration: 200; easing.type: Easing.OutQuad }
                            NumberAnimation { target: padlock; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                        }
                    }
                }

                Connections {
                    target: root.ctx
                    function onSucceededChanged() {
                        if (root.ctx.succeeded) {
                            unlockAnim.restart()
                        } else {
                            unlockAnim.stop()
                            padlock.shackle = 0
                            padlock.morph   = 0
                            padlock.scale   = 1
                        }
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
