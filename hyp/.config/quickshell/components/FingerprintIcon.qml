import QtQuick
import qs.common

// Fingerprint icon — canvas-drawn concentric arcs morphing into a green tick.
//
// API
//   scanning   bool  — subtle pulse while waiting for auth
//   iconColor  color — tint; set to Theme.red on error
//   morph      real  — 0 = fingerprint, 1 = tick
//   signal morphComplete()
//   unlockAnim / revertAnim — restart() from outside
Item {
    id: root

    implicitWidth:  32
    implicitHeight: 32

    // ── Public ────────────────────────────────────────────────────────────
    property bool  scanning:  true
    property color iconColor: Theme.blue
    property real  morph:     0

    signal morphComplete()

    property alias unlockAnim: unlockAnim
    property alias revertAnim: revertAnim

    // ── Canvas ────────────────────────────────────────────────────────────
    onMorphChanged: cv.requestPaint()

    // Subtle breathing pulse while scanning
    SequentialAnimation {
        id: pulseAnim
        running: root.scanning && root.morph < 0.05
        loops:   Animation.Infinite
        NumberAnimation { target: root; property: "scale"; to: 1.06; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "scale"; to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
    }

    // ── Fingerprint glyph ─────────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        text:           "󰈷"
        font.family:    Theme.nerdFont
        font.pixelSize: Math.min(root.width, root.height)
        color:          root.iconColor
        opacity:        Math.max(0, 1 - root.morph * 1.6)

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Tick canvas ───────────────────────────────────────────────────────
    Canvas {
        id: cv
        anchors.fill: parent
        visible:      root.morph > 0.01
        opacity:      Math.min(1, root.morph * 2)
        smooth:       true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.lineCap  = "round"
            ctx.lineJoin = "round"

            const W = width, H = height

            function cs(c) {
                return `rgba(${Math.round(c.r*255)},${Math.round(c.g*255)},${Math.round(c.b*255)},${c.a})`
            }

            const s  = W / 36
            const A  = { x: 7*s,  y: 20*s }
            const B  = { x: 14*s, y: 27*s }
            const C  = { x: 29*s, y: 10*s }
            const l1 = Math.hypot(B.x - A.x, B.y - A.y)
            const l2 = Math.hypot(C.x - B.x, C.y - B.y)
            const p  = root.morph * (l1 + l2)

            ctx.lineWidth   = Math.max(2.5, H * 0.10)
            ctx.strokeStyle = cs(Theme.green)
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

    // ── Animations ────────────────────────────────────────────────────────
    SequentialAnimation {
        id: unlockAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "morph";  to: 1.0; duration: 500; easing.type: Easing.InOutCubic }
            SequentialAnimation {
                NumberAnimation { target: root; property: "scale"; to: 1.15; duration: 250; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "scale"; to: 1.0;  duration: 250; easing.type: Easing.OutQuad }
            }
        }
        ScriptAction { script: root.morphComplete() }
    }

    ParallelAnimation {
        id: revertAnim
        NumberAnimation { target: root; property: "morph";  to: 0; duration: 300; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "scale";  to: 1; duration: 250 }
    }
}
