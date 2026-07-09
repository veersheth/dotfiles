import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import qs.common
import qs.wallpaper

// The lock face: blurred wallpaper, clock, date, battery, password box.
Item {
    id: root

    required property var ctx

    // hidden source for the blur
    Image {
        id: wall
        anchors.fill: parent
        source: WallpaperService.current.length > 0
            ? "file://" + WallpaperService.current
            : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blurMax: 48
        blur: 0.85
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    Canvas {
        id: fingerprintGlow
        anchors { right: parent.right; bottom: parent.bottom }
        width: 340
        height: 340
        opacity: root.ctx.fingerprintListening ? 0.75 : 0
        visible: opacity > 0

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const g = ctx.createRadialGradient(width, height, 0, width, height, width);
            g.addColorStop(0.00, Qt.alpha(Theme.green, 0.34));
            g.addColorStop(0.32, Qt.alpha(Theme.green, 0.16));
            g.addColorStop(0.68, Qt.alpha(Theme.blue, 0.07));
            g.addColorStop(1.00, "transparent");

            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }

        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        SequentialAnimation on scale {
            running: root.ctx.fingerprintListening
            loops: Animation.Infinite
            NumberAnimation { to: 1.05; duration: 1200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.00; duration: 1200; easing.type: Easing.InOutSine }
        }
    }

    // fade in on lock; also arm auth — surfaces only exist while the
    // session is actually locked, so this is the reliable trigger
    opacity: 0
    Component.onCompleted: {
        opacity = 1;
        input.forceActiveFocus();
        ctx.begin();
    }
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // ── Battery (top right, laptops only) ─────────────────────────────
    Row {
        anchors { top: parent.top; right: parent.right; margins: 28 }
        spacing: 8
        visible: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery

        readonly property var battery: UPower.displayDevice
        readonly property real percent: (battery?.percentage ?? 0) * 100
        readonly property bool charging:
            battery !== null &&
            (battery.state === UPowerDeviceState.Charging ||
             battery.state === UPowerDeviceState.FullyCharged ||
             battery.state === UPowerDeviceState.PendingCharge)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (parent.charging) return "󰂄";
                const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
                return icons[Math.min(9, Math.max(0, Math.floor(parent.percent / 10)))];
            }
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize + 1
            color: Qt.alpha(Theme.foreground, 0.8)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(parent.percent)}%`
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Qt.alpha(Theme.foreground, 0.8)
        }
    }

    // ── Clock + date + password ────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
        spacing: 10

        // Padlock → tick morph, Face ID style: the shackle swings open,
        // then the lock dissolves while a green tick draws itself in.
        Item {
            id: padlock

            property real shackle: 0   // 0 closed → 1 swung open
            property real morph:   0   // 0 padlock → 1 green tick

            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 34

            onShackleChanged: cv.requestPaint()
            onMorphChanged:   cv.requestPaint()

            Canvas {
                id: cv
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.lineWidth = 2.6;
                    ctx.lineCap   = "round";
                    ctx.lineJoin  = "round";

                    const t = padlock.morph;

                    // padlock, fading out as the morph progresses
                    const lockAlpha = 0.85 * Math.max(0, 1 - t * 1.6);
                    if (lockAlpha > 0.01) {
                        ctx.globalAlpha = lockAlpha;
                        ctx.strokeStyle = Theme.foreground;

                        // body: rounded rect
                        const x = 9, y = 15.5, bw = 16, bh = 12, r = 3.5;
                        ctx.beginPath();
                        ctx.moveTo(x + r, y);
                        ctx.lineTo(x + bw - r, y); ctx.arcTo(x + bw, y, x + bw, y + r, r);
                        ctx.lineTo(x + bw, y + bh - r); ctx.arcTo(x + bw, y + bh, x + bw - r, y + bh, r);
                        ctx.lineTo(x + r, y + bh); ctx.arcTo(x, y + bh, x, y + bh - r, r);
                        ctx.lineTo(x, y + r); ctx.arcTo(x, y, x + r, y, r);
                        ctx.closePath();
                        ctx.stroke();

                        // shackle: arc that swings open around its left leg
                        ctx.save();
                        ctx.translate(11.5, 15.5);
                        ctx.rotate(-padlock.shackle * 1.0);
                        ctx.translate(-11.5, -15.5);
                        ctx.beginPath();
                        ctx.arc(17, 15.5, 5.5, Math.PI, 2 * Math.PI, false);
                        ctx.stroke();
                        ctx.restore();
                    }

                    // tick, drawing itself on in green
                    if (t > 0.01) {
                        const A = { x: 8,  y: 19 };
                        const B = { x: 14, y: 25 };
                        const C = { x: 26, y: 11 };
                        const l1 = Math.hypot(B.x - A.x, B.y - A.y);
                        const l2 = Math.hypot(C.x - B.x, C.y - B.y);
                        const p  = t * (l1 + l2);

                        ctx.globalAlpha = Math.min(1, t * 2);
                        ctx.strokeStyle = Theme.green;
                        ctx.beginPath();
                        ctx.moveTo(A.x, A.y);
                        if (p <= l1) {
                            const k = p / l1;
                            ctx.lineTo(A.x + (B.x - A.x) * k, A.y + (B.y - A.y) * k);
                        } else {
                            ctx.lineTo(B.x, B.y);
                            const k = (p - l1) / l2;
                            ctx.lineTo(B.x + (C.x - B.x) * k, B.y + (C.y - B.y) * k);
                        }
                        ctx.stroke();
                    }
                }
            }

            // shackle swings, then the morph runs while the icon breathes
            SequentialAnimation {
                id: unlockAnim
                NumberAnimation { target: padlock; property: "shackle"; to: 1; duration: 180; easing.type: Easing.InOutQuad }
                ParallelAnimation {
                    NumberAnimation { target: padlock; property: "morph"; to: 1; duration: 400; easing.type: Easing.InOutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: padlock; property: "scale"; to: 1.18; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { target: padlock; property: "scale"; to: 1;    duration: 200; easing.type: Easing.OutQuad }
                    }
                }
            }

            Connections {
                target: root.ctx
                function onSucceededChanged() {
                    if (root.ctx.succeeded) {
                        unlockAnim.restart();
                    } else {
                        unlockAnim.stop();
                        padlock.shackle = 0;
                        padlock.morph = 0;
                        padlock.scale = 1;
                    }
                }
            }
        }

        Item { width: 1; height: 6 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.family: Theme.font
            font.pixelSize: 92
            font.weight: Font.DemiBold
            color: Theme.foreground
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.Medium
            color: Qt.alpha(Theme.foreground, 0.7)
        }

        Item { width: 1; height: 34 }

        // Password box
        Rectangle {
            id: box
            anchors.horizontalCenter: parent.horizontalCenter
            width: 270
            height: 44
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: Theme.borderWidth
            border.color: root.ctx.status === "Incorrect password"
                ? Qt.alpha(Theme.red, 0.7) : Theme.border

            transform: Translate { id: shakeT }

            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.foreground
                enabled: !root.ctx.authenticating && !root.ctx.succeeded
                clip: true

                onTextChanged: root.ctx.currentText = text
                onAccepted: root.ctx.submit()

                Connections {
                    target: root.ctx
                    function onCurrentTextChanged() {
                        if (root.ctx.currentText === "") input.text = "";
                    }
                    function onFailed() { shake.restart() }
                }
            }

            Text {
                anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                visible: input.text === "" && !input.activeFocus
                text: "password"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Qt.alpha(Theme.foreground, 0.35)
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeT; property: "x"; to: -12; duration: 45 }
                NumberAnimation { target: shakeT; property: "x"; to: 10;  duration: 45 }
                NumberAnimation { target: shakeT; property: "x"; to: -6;  duration: 45 }
                NumberAnimation { target: shakeT; property: "x"; to: 4;   duration: 45 }
                NumberAnimation { target: shakeT; property: "x"; to: 0;   duration: 45 }
            }
        }

        Item { width: 1; height: 4 }

        // Status: fingerprint prompts, auth errors
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.ctx.authenticating ? "Authenticating…" : root.ctx.status
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: root.ctx.status === "Incorrect password"
                ? Qt.alpha(Theme.red, 0.9) : Qt.alpha(Theme.foreground, 0.55)
        }
    }
}
