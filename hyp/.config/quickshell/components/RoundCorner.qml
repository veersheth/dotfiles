import QtQuick
import qs.common

// Concave corner drawn just below the bar so the screen appears to
// "melt" out of it. Fill matches the bar background; the arc is stroked
// with the border color so the bar's bottom hairline flows through it.
Canvas {
    id: root
    property bool rightSide: false

    implicitWidth: Theme.radius
    implicitHeight: Theme.radius

    onPaint: {
        const ctx = getContext("2d");
        const r = width;
        ctx.reset();

        ctx.beginPath();
        if (!rightSide) {
            ctx.moveTo(0, 0);
            ctx.lineTo(r, 0);
            ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true);
        } else {
            ctx.moveTo(r, 0);
            ctx.lineTo(0, 0);
            ctx.arc(0, r, r, -Math.PI / 2, 0, false);
        }
        ctx.closePath();
        ctx.fillStyle = Theme.background;
        ctx.fill();

        // continue the bar's bottom border along the curve
        ctx.beginPath();
        if (!rightSide) ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true);
        else            ctx.arc(0, r, r, -Math.PI / 2, 0, false);
        ctx.strokeStyle = Theme.border;
        ctx.lineWidth = Theme.borderWidth;
        ctx.stroke();
    }
}
