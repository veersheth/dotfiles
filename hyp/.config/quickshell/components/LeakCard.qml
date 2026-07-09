import QtQuick
import QtQuick.Effects
import qs.common

// Canvas-drawn card that "leaks" from a bar edge. Concave flares at the
// neck connect it to the bar hairline; bottom corners are rounded.
// Animate `progress` 0→1 to morph from a pill nub into the full card.
Item {
    id: root

    default property alias content: contentItem.data
    property real contentWidth: 200
    property real contentHeight: 200
    property real progress: 1

    property real startWidth:  contentWidth * 0.35
    property real startHeight: Theme.pillHeight

    // concave radius where the card neck meets the bar
    property real flare: Theme.popupRadius
    // pixels the neck tucks under the bar hairline
    property real overlap: Theme.borderWidth

    readonly property real cardWidth:  lerp(startWidth,  contentWidth,  progress)
    readonly property real cardHeight: lerp(startHeight, contentHeight, progress)

    opacity: Math.min(1, progress * 4)

    function lerp(a, b, t) { return a + (b - a) * t }

    Canvas {
        id: cv
        anchors.fill: parent

        readonly property real cw: root.cardWidth
        readonly property real ch: root.cardHeight + root.overlap
        onCwChanged: requestPaint()
        onChChanged: requestPaint()
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const m  = root.flare;
            const left  = (width - cw) / 2;
            const right = left + cw;
            const br = Math.min(
                root.lerp(root.startHeight / 2, Theme.popupRadius, root.progress),
                ch / 2, cw / 2);

            ctx.beginPath();
            ctx.moveTo(left - m, 0);
            ctx.arc(left - m, m, m, -Math.PI / 2, 0, false);              // left flare
            ctx.lineTo(left, ch - br);
            ctx.arc(left + br,  ch - br, br, Math.PI,      Math.PI / 2, true); // bottom-left
            ctx.lineTo(right - br, ch);
            ctx.arc(right - br, ch - br, br, Math.PI / 2,  0,            true); // bottom-right
            ctx.lineTo(right, m);
            ctx.arc(right + m, m, m, Math.PI, Math.PI * 1.5, false);     // right flare

            ctx.fillStyle   = Theme.background;
            ctx.fill();
            ctx.strokeStyle = Theme.border;
            ctx.lineWidth   = Theme.borderWidth;
            ctx.stroke();
        }
    }

    // content clipped to the morphing card rect
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y:      root.overlap
        width:  root.cardWidth
        height: root.cardHeight
        clip:   true

        Item {
            id: contentItem
            anchors.top:              parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width:   root.contentWidth
            height:  root.contentHeight
            opacity: Math.max(0, (root.progress - 0.35) / 0.65)

            // Dynamic-island blur: content sharpens as the card reaches full
            // size. Layer only exists mid-morph so the settled popup renders
            // without the offscreen pass.
            layer.enabled: root.progress < 0.999
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax:     40
                blur:        Math.min(1, Math.max(0, 1 - root.progress))
            }
        }
    }
}
