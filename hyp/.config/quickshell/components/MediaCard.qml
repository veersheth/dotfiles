import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Month calendar with a vertically scrolling month strip. Navigate with
// ‹ › (months), « » (years), or the scroll wheel; click the title to jump
// back to today. To the right: analog clock, album art circle, and media
// info/controls, all centered on one horizontal line.
BarPopup {
    id: root

    property var today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    property double selectedMs: -1

    // Qt convention: 1 = Monday .. 7 = Sunday; %7 maps onto JS getDay()
    readonly property int firstDow: Qt.locale().firstDayOfWeek

    readonly property int cellW: 34
    readonly property int cellH: 30

    // month strip range; keeps ListView indices manageable
    readonly property int minYear: 1900
    readonly property int maxYear: 2100

    contentWidth: mainRow.implicitWidth + 44
    contentHeight: mainRow.implicitHeight + 44

    onShownChanged: if (shown) goToday()

    function goToday() {
        today = new Date();
        month = today.getMonth();
        year = today.getFullYear();
        selectedMs = -1;
    }

    function addMonths(n) {
        const total = Math.max(minYear * 12,
            Math.min(maxYear * 12 + 11, year * 12 + month + n));
        year = Math.floor(total / 12);
        month = total % 12;
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    component NavButton: Rectangle {
        property alias label: navText.text
        signal activated()

        implicitWidth: 26
        implicitHeight: 26
        radius: Theme.smallRadius
        color: navMouse.containsMouse ? Theme.hoverStrong : "transparent"

        Text {
            id: navText
            anchors.centerIn: parent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
            color: Theme.foreground
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.activated()
        }
    }

    // iOS-style media button: no background, just a bold icon drawn on a
    // Canvas. Dims and shrinks slightly while pressed.
    component MediaButton: Item {
        id: mb
        property string kind: "play"        // "prev" | "play" | "pause" | "next"
        property color iconColor: Theme.foreground
        signal activated()

        implicitHeight: 56
        scale: mbMouse.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

        Canvas {
            id: icon
            anchors.fill: parent
            antialiasing: true
            opacity: mbMouse.pressed ? 0.5 : 1.0
            Behavior on opacity { NumberAnimation { duration: 90 } }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: mb
                function onKindChanged() { icon.requestPaint() }
                function onIconColorChanged() { icon.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2, cy = height / 2
                ctx.fillStyle = mb.iconColor
                ctx.strokeStyle = mb.iconColor
                ctx.lineJoin = "round"
                ctx.lineCap = "round"

                function tri(w, x1, y1, x2, y2, x3, y3) {
                    ctx.lineWidth = w
                    ctx.beginPath()
                    ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.lineTo(x3, y3)
                    ctx.closePath()
                    ctx.fill(); ctx.stroke()
                }

                if (mb.kind === "play") {
                    tri(6, cx - 9, cy - 14, cx + 14, cy, cx - 9, cy + 14)
                } else if (mb.kind === "pause") {
                    ctx.lineWidth = 9
                    ctx.beginPath()
                    ctx.moveTo(cx - 7, cy - 11); ctx.lineTo(cx - 7, cy + 11)
                    ctx.moveTo(cx + 7, cy - 11); ctx.lineTo(cx + 7, cy + 11)
                    ctx.stroke()
                } else if (mb.kind === "next") {          // ▶▶
                    tri(4, cx - 16, cy - 11, cx - 1, cy, cx - 16, cy + 11)
                    tri(4, cx - 1,  cy - 11, cx + 14, cy, cx - 1,  cy + 11)
                } else if (mb.kind === "prev") {          // ◀◀
                    tri(4, cx + 16, cy - 11, cx + 1, cy, cx + 16, cy + 11)
                    tri(4, cx + 1,  cy - 11, cx - 14, cy, cx + 1,  cy + 11)
                }
            }
        }

        MouseArea {
            id: mbMouse
            anchors.fill: parent
            onClicked: mb.activated()
        }
    }

    // Spinning vinyl record: album art as the disc, engraved grooves and a
    // centre label that rotate with it, plus a static light sheen on top so
    // the "reflection" stays put while the record turns. Art cross-fades on
    // track change; rotation pauses (not resets) when playback pauses.
    component Vinyl: Item {
        id: vinyl
        property string artUrl: ""
        property bool spinning: false
        property bool active: true            // false → stop animating entirely
        property int rpmMs: 9000              // ms per revolution

        property string _slotA: ""
        property string _slotB: ""
        property bool _useA: true
        property bool _ready: false

        onArtUrlChanged: {
            if (!_ready) return
            if (_useA) { _slotB = artUrl; _useA = false }
            else       { _slotA = artUrl; _useA = true }
        }
        Component.onCompleted: { _slotA = artUrl; _ready = true }

        // rotating part: art + grooves + label
        Item {
            id: disc
            anchors.fill: parent

            ClippingRectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#0d0d0d"

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: vinyl._slotA
                    opacity: vinyl._useA ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                }
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: vinyl._slotB
                    opacity: vinyl._useA ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                }
            }

            Canvas {
                anchors.fill: parent
                antialiasing: true
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2, r = Math.min(cx, cy)

                    // darken towards the rim
                    const vgn = ctx.createRadialGradient(cx, cy, r * 0.5, cx, cy, r)
                    vgn.addColorStop(0, "rgba(0,0,0,0.10)")
                    vgn.addColorStop(1, "rgba(0,0,0,0.62)")
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.fillStyle = vgn; ctx.fill()

                    // run-in ring and lead-out ring
                    ctx.strokeStyle = "rgba(0,0,0,0.45)"; ctx.lineWidth = 2
                    ctx.beginPath(); ctx.arc(cx, cy, r - 5, 0, Math.PI * 2); ctx.stroke()
                    ctx.beginPath(); ctx.arc(cx, cy, r * 0.36, 0, Math.PI * 2); ctx.stroke()

                    // grooves, alternating weight for a banded look
                    ctx.lineWidth = 1
                    let k = 0
                    for (let ri = r * 0.40; ri < r - 8; ri += 4.5, k++) {
                        ctx.strokeStyle = (k % 3 === 0) ? "rgba(0,0,0,0.30)" : "rgba(0,0,0,0.14)"
                        ctx.beginPath(); ctx.arc(cx, cy, ri, 0, Math.PI * 2); ctx.stroke()
                    }

                    // centre label
                    const lr = r * 0.27
                    const lbl = ctx.createRadialGradient(cx, cy, 0, cx, cy, lr)
                    lbl.addColorStop(0, "rgba(0,0,0,0.80)")
                    lbl.addColorStop(1, "rgba(0,0,0,0.58)")
                    ctx.beginPath(); ctx.arc(cx, cy, lr, 0, Math.PI * 2)
                    ctx.fillStyle = lbl; ctx.fill()
                    ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 1.5; ctx.stroke()

                    // spindle hole
                    ctx.beginPath(); ctx.arc(cx, cy, 5, 0, Math.PI * 2)
                    ctx.fillStyle = "#0a0a0a"; ctx.fill()
                    ctx.strokeStyle = "rgba(255,255,255,0.28)"; ctx.lineWidth = 1; ctx.stroke()
                }
            }
        }

        // static sheen: two opposing light wedges, doesn't rotate with the disc
        Canvas {
            anchors.fill: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2, cy = height / 2, r = Math.min(cx, cy)
                const g = ctx.createConicalGradient(cx, cy, Math.PI * 0.22)
                g.addColorStop(0.00, "rgba(255,255,255,0)")
                g.addColorStop(0.07, "rgba(255,255,255,0.17)")
                g.addColorStop(0.15, "rgba(255,255,255,0)")
                g.addColorStop(0.50, "rgba(255,255,255,0)")
                g.addColorStop(0.57, "rgba(255,255,255,0.11)")
                g.addColorStop(0.65, "rgba(255,255,255,0)")
                g.addColorStop(1.00, "rgba(255,255,255,0)")
                ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.fillStyle = g; ctx.fill()

                // thin rim highlight
                ctx.beginPath(); ctx.arc(cx, cy, r - 0.5, 0, Math.PI * 2)
                ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 1; ctx.stroke()
            }
        }

        // placeholder when there's no art
        Text {
            anchors.centerIn: parent
            visible: vinyl.artUrl === ""
            text: "󰎆"
            font.family: Theme.font
            font.pixelSize: 56
            color: Qt.alpha(Theme.foreground, 0.18)
        }

        RotationAnimator {
            target: disc
            from: 0
            to: 360
            duration: vinyl.rpmMs
            loops: Animation.Infinite
            running: vinyl.active
            paused: !vinyl.spinning
        }
    }

    QtObject {
        id: mediaHost
        property var _lastPlayer: null
        readonly property var player: {
            const players = Mpris.players.values
            if (players.length === 0) return null
            for (const p of players)
                if (p.playbackState === MprisPlaybackState.Playing) {
                    _lastPlayer = p; return p
                }
            if (_lastPlayer !== null)
                for (const p of players)
                    if (p === _lastPlayer) return p
            if (players.length > 0) { _lastPlayer = players[0]; return players[0] }
            return null
        }
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 40

        // ── Calendar column ───────────────────────────────────────────
        ColumnLayout {
            id: col
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            // ── Header: ⇑ ↑ Month Year ↓ ⇓ ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                NavButton { label: "󰄿"; onActivated: root.addMonths(-12) }
                NavButton { label: ""; onActivated: root.addMonths(-1) }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Theme.smallRadius
                    color: titleMouse.containsMouse ? Theme.hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                    }

                    MouseArea {
                        id: titleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.goToday()
                    }
                }

                NavButton { label: ""; onActivated: root.addMonths(1) }
                NavButton { label: "󰄼"; onActivated: root.addMonths(12) }
            }

            // ── Day-of-week labels ────────────────────────────────────
            Row {
                spacing: 2
                Repeater {
                    model: 7
                    Text {
                        required property int index
                        width: root.cellW
                        horizontalAlignment: Text.AlignHCenter
                        // any week works; grid columns always start on firstDow
                        text: Qt.locale().dayName(
                            (root.firstDow - 1 + index) % 7 + 1, Locale.ShortFormat)
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        color: Qt.alpha(Theme.foreground, 0.5)
                    }
                }
            }

            // ── Vertically scrolling month strip ──────────────────────
            Item {
                Layout.preferredWidth: 7 * root.cellW + 6 * 2
                Layout.preferredHeight: 6 * root.cellH + 5 * 2

                ListView {
                    id: monthList

                    readonly property int baseIndex: root.minYear * 12

                    anchors.fill: parent
                    clip: true
                    interactive: false
                    model: (root.maxYear - root.minYear + 1) * 12

                    currentIndex: root.year * 12 + root.month - baseIndex
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height
                    highlightMoveDuration: 250
                    highlightMoveVelocity: -1

                    // land on the initial month without scrolling there from 1900
                    Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Beginning)

                    delegate: Item {
                        id: monthItem
                        required property int index
                        readonly property int mYear: Math.floor((monthList.baseIndex + index) / 12)
                        readonly property int mMonth: (monthList.baseIndex + index) % 12
                        readonly property int mOffset:
                            (new Date(mYear, mMonth, 1).getDay() - root.firstDow % 7 + 7) % 7

                        width: monthList.width
                        height: monthList.height + 10   // gap only visible mid-scroll

                        Grid {
                            columns: 7
                            columnSpacing: 2
                            rowSpacing: 2

                            Repeater {
                                model: 42
                                Rectangle {
                                    required property int index
                                    readonly property var day: new Date(
                                        monthItem.mYear, monthItem.mMonth,
                                        1 - monthItem.mOffset + index)
                                    readonly property bool inMonth:
                                        day.getMonth() === monthItem.mMonth
                                    readonly property bool isToday: root.isSameDay(day, root.today)
                                    readonly property bool isSelected: day.getTime() === root.selectedMs

                                    width: root.cellW
                                    height: root.cellH
                                    radius: Theme.smallRadius
                                    color: isToday ? Theme.blue
                                         : isSelected ? Theme.hoverStrong
                                         : dayMouse.containsMouse ? Theme.hover
                                         : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.day.getDate()
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                        font.weight: parent.isToday ? Font.Bold : Font.Medium
                                        color: parent.isToday ? Theme.onAccent
                                             : parent.inMonth ? Theme.foreground
                                             : Qt.alpha(Theme.foreground, 0.3)
                                    }

                                    MouseArea {
                                        id: dayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.selectedMs = parent.day.getTime()
                                    }
                                }
                            }
                        }
                    }
                }

                // Transparent overlay: catches wheel/touchpad events above the
                // ListView so Flickable can't intercept them. Plain Item — no
                // MouseArea — so day clicks still pass through.
                Item {
                    anchors.fill: parent
                    WheelHandler {
                        target: null
                        property real accum: 0
                        onWheel: event => {
                            accum += event.angleDelta.y
                            if (Math.abs(accum) >= 120) {
                                root.addMonths(accum < 0 ? 1 : -1)
                                accum = 0
                            }
                        }
                    }
                }
            }
        }

        // ── Analog clock ──────────────────────────────────────────────
        AnalogClock {
            implicitWidth:  220
            implicitHeight: 220
            Layout.alignment: Qt.AlignVCenter
            running: root.shown
        }

        // ── Spinning vinyl (same size as clock) ───────────────────────
        Vinyl {
            id: vinylRecord
            visible: mediaHost.player !== null
            implicitWidth: 220
            implicitHeight: 220
            Layout.alignment: Qt.AlignVCenter
            artUrl: mediaHost.player?.trackArtUrl ?? ""
            spinning: mediaHost.player?.playbackState === MprisPlaybackState.Playing
            active: root.shown && visible
        }

        // ── Media info + controls ─────────────────────────────────────
        ColumnLayout {
            id: mediaCol
            readonly property var player: mediaHost.player
            readonly property bool hasLength: player !== null
                && player.lengthSupported && player.length > 0

            function fmt(sec) {
                const s = Math.max(0, Math.floor(sec))
                return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
            }

            visible: player !== null
            Layout.preferredWidth: 230
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: mediaCol.player ? (mediaCol.player.trackTitle || "Unknown title") : ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.DemiBold
                color: Theme.foreground
            }

            Text {
                Layout.fillWidth: true
                text: mediaCol.player ? (mediaCol.player.trackArtist || "Unknown artist") : ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                color: Qt.alpha(Theme.foreground, 0.6)
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: mediaCol.player ? (mediaCol.player.trackAlbum || "") : ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                color: Qt.alpha(Theme.foreground, 0.4)
            }

            // seekbar (drag or click to seek)
            Item {
                id: seek
                Layout.fillWidth: true
                Layout.topMargin: 8
                implicitHeight: 18
                visible: mediaCol.hasLength

                readonly property int pad: 6          // half the handle width
                property bool dragging: false
                property real dragFrac: 0
                readonly property real frac: dragging ? dragFrac
                    : (mediaCol.hasLength
                        ? Math.max(0, Math.min(1, mediaCol.player.position / mediaCol.player.length))
                        : 0)

                function fracAt(x) {
                    return Math.max(0, Math.min(1, (x - pad) / (width - 2 * pad)))
                }

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: seek.dragging ? 6 : 4
                    radius: height / 2
                    color: Qt.alpha(Theme.foreground, 0.2)
                    Behavior on height { NumberAnimation { duration: 100 } }

                    Rectangle {
                        width: seek.pad + seek.frac * (seek.width - 2 * seek.pad)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.foreground
                    }
                }

                Rectangle {
                    id: handle
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                    x: seek.pad + seek.frac * (seek.width - 2 * seek.pad) - width / 2
                    scale: seek.dragging ? 1.5 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: mediaCol.player !== null && mediaCol.player.canSeek
                    onPressed: mouse => {
                        seek.dragging = true
                        seek.dragFrac = seek.fracAt(mouse.x)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) seek.dragFrac = seek.fracAt(mouse.x)
                    }
                    onReleased: {
                        if (mediaCol.player && mediaCol.hasLength) {
                            mediaCol.player.position = seek.dragFrac * mediaCol.player.length
                            mediaCol.player.positionChanged()
                        }
                        seek.dragging = false
                    }
                    onCanceled: seek.dragging = false
                }
            }

            // elapsed / remaining
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: -4
                visible: mediaCol.hasLength

                readonly property real elapsed: !mediaCol.hasLength ? 0
                    : seek.dragging ? seek.dragFrac * mediaCol.player.length
                    : mediaCol.player.position

                Text {
                    text: mediaCol.fmt(parent.elapsed)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    color: Qt.alpha(Theme.foreground, 0.6)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "-" + mediaCol.fmt(mediaCol.hasLength ? mediaCol.player.length - parent.elapsed : 0)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    color: Qt.alpha(Theme.foreground, 0.6)
                }
            }

            // MPRIS doesn't push position updates; poll while playing
            Timer {
                interval: 500
                repeat: true
                running: root.shown && mediaCol.player !== null
                         && mediaCol.player.isPlaying && !seek.dragging
                onTriggered: mediaCol.player.positionChanged()
            }

            // controls
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 0

                MediaButton {
                    kind: "prev"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    opacity: mediaCol.player && mediaCol.player.canGoPrevious ? 1 : 0.35
                    onActivated: if (mediaCol.player) mediaCol.player.previous()
                }
                MediaButton {
                    kind: mediaCol.player && mediaCol.player.isPlaying ? "pause" : "play"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    opacity: mediaCol.player && mediaCol.player.canTogglePlaying ? 1 : 0.35
                    onActivated: if (mediaCol.player) mediaCol.player.togglePlaying()
                }
                MediaButton {
                    kind: "next"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    opacity: mediaCol.player && mediaCol.player.canGoNext ? 1 : 0.35
                    onActivated: if (mediaCol.player) mediaCol.player.next()
                }
            }
        }
    }   // RowLayout mainRow
}

