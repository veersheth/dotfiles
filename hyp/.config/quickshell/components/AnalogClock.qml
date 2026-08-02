import QtQuick
import qs.common

// Skeuomorphic analog watch face.
//
// Drop it anywhere and size it with implicitWidth/implicitHeight (default 220).
// Ticks every second while `running` is true (default true).
//
//   AnalogClock { implicitWidth: 180; implicitHeight: 180; running: popup.shown }
Canvas {
    id: root

    property bool running: true

    smooth: true

    // Repaint immediately on first load, then every second while running
    Component.onCompleted: requestPaint()

    Timer {
        interval: 1000
        repeat:   true
        running:  root.running
        onTriggered: root.requestPaint()
    }

    onPaint: {
        const ctx = getContext("2d")
        const W = width, H = height
        const cx = W / 2, cy = H / 2
        const R  = Math.min(W, H) / 2 - 2   // outermost radius
        const fR = R - 8                      // glass face radius

        ctx.clearRect(0, 0, W, H)

        // ── Outer metallic bezel ──────────────────────────────────────
        const bezel = ctx.createRadialGradient(
            cx - R * 0.22, cy - R * 0.28, R * 0.08,
            cx, cy, R)
        bezel.addColorStop(0.00, "#8e8ea0")
        bezel.addColorStop(0.25, "#5a5a70")
        bezel.addColorStop(0.60, "#2a2a3c")
        bezel.addColorStop(0.85, "#17172a")
        bezel.addColorStop(1.00, "#0d0d1a")
        ctx.beginPath()
        ctx.arc(cx, cy, R, 0, Math.PI * 2)
        ctx.fillStyle = bezel
        ctx.fill()

        // Highlight rim at top-left
        ctx.beginPath()
        ctx.arc(cx, cy, R - 1, -Math.PI * 0.85, -Math.PI * 0.05)
        ctx.strokeStyle = "rgba(200,200,230,0.18)"
        ctx.lineWidth = 1.5
        ctx.stroke()

        // ── Inset shadow ring (depth between bezel and face) ──────────
        ctx.beginPath()
        ctx.arc(cx, cy, fR + 3, 0, Math.PI * 2)
        ctx.strokeStyle = "rgba(0,0,0,0.7)"
        ctx.lineWidth = 4
        ctx.stroke()

        // ── Clock face (dark sapphire glass) ──────────────────────────
        const face = ctx.createRadialGradient(
            cx - fR * 0.12, cy - fR * 0.18, fR * 0.02,
            cx, cy, fR)
        face.addColorStop(0.00, "#1e2038")
        face.addColorStop(0.40, "#141626")
        face.addColorStop(0.80, "#0e1020")
        face.addColorStop(1.00, "#090b18")
        ctx.beginPath()
        ctx.arc(cx, cy, fR, 0, Math.PI * 2)
        ctx.fillStyle = face
        ctx.fill()

        // Vignette
        const vignette = ctx.createRadialGradient(cx, cy, fR * 0.45, cx, cy, fR)
        vignette.addColorStop(0.0, "rgba(0,0,0,0)")
        vignette.addColorStop(1.0, "rgba(0,0,0,0.5)")
        ctx.beginPath()
        ctx.arc(cx, cy, fR, 0, Math.PI * 2)
        ctx.fillStyle = vignette
        ctx.fill()

        // ── Glass reflection (clipped to face) ────────────────────────
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, fR, 0, Math.PI * 2)
        ctx.clip()
        const shine = ctx.createLinearGradient(
            cx - fR * 0.55, cy - fR,
            cx + fR * 0.35, cy * 0.2)
        shine.addColorStop(0.0, "rgba(255,255,255,0.09)")
        shine.addColorStop(0.5, "rgba(255,255,255,0.03)")
        shine.addColorStop(1.0, "rgba(255,255,255,0)")
        ctx.fillStyle = shine
        ctx.fillRect(cx - fR, cy - fR, fR * 2, fR * 2)
        ctx.restore()

        // ── Tick marks ────────────────────────────────────────────────
        for (let i = 0; i < 60; i++) {
            const a     = (i / 60) * Math.PI * 2 - Math.PI / 2
            const isH   = i % 5 === 0
            const outer = fR * 0.91
            const inner = fR * (isH ? 0.77 : 0.87)
            ctx.beginPath()
            ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
            ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
            ctx.strokeStyle = isH
                ? "rgba(200,210,255,0.72)"
                : "rgba(180,190,255,0.18)"
            ctx.lineWidth = isH ? 2.5 : 1
            ctx.lineCap   = "round"
            ctx.stroke()
        }

        // ── Date window at 3 o'clock ──────────────────────────────────
        const now = new Date()
        const dX  = cx + fR * 0.52, dY = cy
        const dW  = 22, dH = 16, dr = 3
        ctx.save()
        ctx.shadowColor = "rgba(0,0,0,0.6)"
        ctx.shadowBlur  = 4
        ctx.beginPath()
        ctx.moveTo(dX - dW / 2 + dr, dY - dH / 2)
        ctx.lineTo(dX + dW / 2 - dr, dY - dH / 2)
        ctx.arcTo(dX + dW / 2, dY - dH / 2, dX + dW / 2, dY - dH / 2 + dr, dr)
        ctx.lineTo(dX + dW / 2, dY + dH / 2 - dr)
        ctx.arcTo(dX + dW / 2, dY + dH / 2, dX + dW / 2 - dr, dY + dH / 2, dr)
        ctx.lineTo(dX - dW / 2 + dr, dY + dH / 2)
        ctx.arcTo(dX - dW / 2, dY + dH / 2, dX - dW / 2, dY + dH / 2 - dr, dr)
        ctx.lineTo(dX - dW / 2, dY - dH / 2 + dr)
        ctx.arcTo(dX - dW / 2, dY - dH / 2, dX - dW / 2 + dr, dY - dH / 2, dr)
        ctx.closePath()
        ctx.fillStyle = "#dde0ee"
        ctx.fill()
        ctx.shadowColor = "transparent"
        ctx.shadowBlur  = 0
        ctx.strokeStyle = "rgba(140,150,200,0.45)"
        ctx.lineWidth   = 0.5
        ctx.stroke()
        ctx.fillStyle    = "#14162a"
        ctx.font         = "bold 10px sans-serif"
        ctx.textAlign    = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(now.getDate(), dX, dY + 0.5)
        ctx.restore()

        // ── Hands ─────────────────────────────────────────────────────
        const hr  = now.getHours() % 12
        const min = now.getMinutes()
        const sec = now.getSeconds()
        const hA  = ((hr + min / 60) / 12) * Math.PI * 2 - Math.PI / 2
        const mA  = ((min + sec / 60) / 60) * Math.PI * 2 - Math.PI / 2
        const sA  = (sec / 60) * Math.PI * 2 - Math.PI / 2

        function drawHand(angle, len, tail, width, color, glowColor) {
            const tipX  = cx + Math.cos(angle) * len
            const tipY  = cy + Math.sin(angle) * len
            const tailX = cx + Math.cos(angle + Math.PI) * tail
            const tailY = cy + Math.sin(angle + Math.PI) * tail

            // Lume glow pass
            if (glowColor) {
                ctx.beginPath()
                ctx.moveTo(tailX, tailY)
                ctx.lineTo(tipX, tipY)
                ctx.strokeStyle = glowColor
                ctx.lineWidth   = width * 4
                ctx.lineCap     = "round"
                ctx.stroke()
            }

            // Hand with drop shadow
            ctx.save()
            ctx.shadowColor   = "rgba(0,0,0,0.65)"
            ctx.shadowBlur    = 6
            ctx.shadowOffsetX = 1
            ctx.shadowOffsetY = 1
            ctx.beginPath()
            ctx.moveTo(tailX, tailY)
            ctx.lineTo(tipX, tipY)
            ctx.strokeStyle = color
            ctx.lineWidth   = width
            ctx.lineCap     = "round"
            ctx.stroke()
            ctx.restore()
        }

        // Hour — broad, short
        drawHand(hA, fR * 0.40, fR * 0.10, 5.0,
            "rgba(235,238,255,0.93)",
            "rgba(190,200,255,0.07)")

        // Minute — slender, long
        drawHand(mA, fR * 0.75, fR * 0.12, 2.8,
            "rgba(220,225,255,0.88)",
            "rgba(190,200,255,0.06)")

        // Second — accent blue with visible glow
        drawHand(sA, fR * 0.83, fR * 0.22, 1.5,
            "#a7b8dd",
            "rgba(167,184,221,0.14)")

        // ── Center boss ───────────────────────────────────────────────
        const boss = ctx.createRadialGradient(cx - 1.5, cy - 1.5, 0.5, cx, cy, 7.5)
        boss.addColorStop(0.0, "#b0b8d0")
        boss.addColorStop(0.5, "#5c6280")
        boss.addColorStop(1.0, "#282c44")
        ctx.beginPath()
        ctx.arc(cx, cy, 7.5, 0, Math.PI * 2)
        ctx.fillStyle = boss
        ctx.fill()
        // Accent ring
        ctx.beginPath()
        ctx.arc(cx, cy, 4, 0, Math.PI * 2)
        ctx.fillStyle = "#a7b8dd"
        ctx.fill()
        // Specular highlight
        ctx.beginPath()
        ctx.arc(cx - 1.2, cy - 1.2, 1.5, 0, Math.PI * 2)
        ctx.fillStyle = "rgba(255,255,255,0.65)"
        ctx.fill()
    }
}
