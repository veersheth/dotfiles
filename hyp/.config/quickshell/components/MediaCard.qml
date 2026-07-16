import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common

// Self-contained media player card. Pass a player; set active: false when
// the card isn't visible so the position timer doesn't tick needlessly.
// Used by bar/popups/MediaPopup (wrapped in BarPopup) and lock/LockSurface.
Item {
    id: root

    property var  player:  null
    property bool active:  true   // false → pause the position-sync timer

    readonly property bool playing:
        player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property real length: player?.length ?? 0
    readonly property string artUrl: player?.trackArtUrl ?? ""

    property real pos:             0
    property bool seeking:         false
    property real seekPreviewFrac: 0
    readonly property real seekFrac: seeking
        ? seekPreviewFrac
        : (length > 0 ? Math.min(1, pos / length) : 0)

    property color accentColor: Theme.blue
    Behavior on accentColor { ColorAnimation { duration: 500 } }

    property string _slotA: ""
    property string _slotB: ""
    property bool   _useA:  true

    implicitWidth:  300
    implicitHeight: col.implicitHeight

    function syncPos() { pos = player?.position ?? 0 }
    function fmtTime(s) {
        s = Math.max(0, Math.round(s));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    onArtUrlChanged: {
        if (_useA) { _slotB = artUrl; _useA = false; }
        else       { _slotA = artUrl; _useA = true;  }
        colorExtract.extract(artUrl);
    }
    Component.onCompleted: { _slotA = artUrl; colorExtract.extract(artUrl); }

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.active && root.player !== null && !root.seeking
        onTriggered: root.syncPos()
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        // ── Vinyl record ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 234
            Layout.topMargin: 20
            clip: true

            Rectangle {
                anchors.centerIn: vinyl
                width: vinyl.width + 36; height: width; radius: width / 2
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.09)
                z: -1
                Behavior on color { ColorAnimation { duration: 500 } }
            }
            Rectangle {
                anchors.centerIn: vinyl
                width: vinyl.width + 18; height: width; radius: width / 2
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                z: -1
                Behavior on color { ColorAnimation { duration: 500 } }
            }

            Item {
                id: vinyl
                width: 196; height: 196
                anchors.centerIn: parent

                ClippingRectangle {
                    anchors.fill: parent; radius: width / 2; color: "#0d0d0d"
                    Image {
                        anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
                        source: root._slotA
                        opacity: root._useA ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                    }
                    Image {
                        anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
                        source: root._slotB
                        opacity: root._useA ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                    }
                }

                Canvas {
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const cx = width / 2, cy = height / 2, r = Math.min(cx, cy);
                        const vgn = ctx.createRadialGradient(cx, cy, r * 0.55, cx, cy, r);
                        vgn.addColorStop(0, "rgba(0,0,0,0)");
                        vgn.addColorStop(1, "rgba(0,0,0,0.60)");
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.fillStyle = vgn; ctx.fill();
                        for (let ri = 32; ri < r - 6; ri += 8) {
                            ctx.beginPath(); ctx.arc(cx, cy, ri, 0, Math.PI * 2);
                            ctx.strokeStyle = "rgba(0,0,0,0.20)";
                            ctx.lineWidth = 1.2; ctx.stroke();
                        }
                        const lbl = ctx.createRadialGradient(cx, cy, 0, cx, cy, 30);
                        lbl.addColorStop(0, "rgba(0,0,0,0.72)");
                        lbl.addColorStop(1, "rgba(0,0,0,0.52)");
                        ctx.beginPath(); ctx.arc(cx, cy, 30, 0, Math.PI * 2);
                        ctx.fillStyle = lbl; ctx.fill();
                        ctx.beginPath(); ctx.arc(cx, cy, 4.5, 0, Math.PI * 2);
                        ctx.fillStyle = "rgba(255,255,255,0.18)"; ctx.fill();
                    }
                }

                Timer {
                    interval: 16; repeat: true
                    running: root.playing && root.active
                    onTriggered: vinyl.rotation = (vinyl.rotation + 360 * 16 / 9000) % 360
                }
            }

            Text {
                anchors.centerIn: vinyl
                visible: !root.artUrl
                text: "󰝚"
                font.family: Theme.nerdFont; font.pixelSize: 52
                color: Qt.alpha(Theme.foreground, 0.15)
            }
        }

        // ── Title ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 14; Layout.leftMargin: 18; Layout.rightMargin: 18
            implicitHeight: titleText.implicitHeight
            clip: true

            Text {
                id: titleText
                text: root.player?.trackTitle ?? ""
                font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold
                color: Theme.foreground
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: titleText.implicitWidth > titleText.parent.width
                    onStopped: titleText.x = 0
                    PauseAnimation  { duration: 2500 }
                    NumberAnimation {
                        to: titleText.parent.width - titleText.implicitWidth
                        duration: Math.max(0, titleText.implicitWidth - titleText.parent.width) * 22
                        easing.type: Easing.Linear
                    }
                    PauseAnimation  { duration: 800 }
                    ScriptAction    { script: titleText.x = 0 }
                }
            }
        }

        // ── Artist + app ───────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; Layout.topMargin: 4
            Layout.leftMargin: 18; Layout.rightMargin: 18; spacing: 2
            Text {
                Layout.fillWidth: true; visible: text !== ""; elide: Text.ElideRight
                text: root.player?.trackArtist ?? ""
                font.family: Theme.font; font.pixelSize: 13
                color: Qt.alpha(Theme.foreground, 0.60)
            }
            Text {
                Layout.fillWidth: true; visible: text !== ""; elide: Text.ElideRight
                text: root.player?.identity ?? ""
                font.family: Theme.font; font.pixelSize: 11
                color: Qt.alpha(Theme.foreground, 0.36)
            }
        }

        // ── Seek bar ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; Layout.topMargin: 16
            Layout.leftMargin: 18; Layout.rightMargin: 18; spacing: 6
            visible: root.length > 0

            Item {
                Layout.fillWidth: true; implicitHeight: 20
                Rectangle {
                    id: seekTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 4; radius: 2
                    color: Qt.alpha(Theme.foreground, 0.12)
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: root.seekFrac * parent.width; radius: 2
                        color: root.accentColor
                        Behavior on color { ColorAnimation { duration: 400 } }
                        Behavior on width {
                            enabled: !root.seeking
                            NumberAnimation { duration: 300; easing.type: Easing.Linear }
                        }
                    }
                    Rectangle {
                        x: Math.max(0, Math.min(seekTrack.width - width, root.seekFrac * seekTrack.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7; color: "white"; z: 1
                        scale: seekArea.containsMouse || seekArea.pressed ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    }
                    MouseArea {
                        id: seekArea
                        anchors { fill: parent; margins: -8 }
                        hoverEnabled: true
                        enabled: root.player?.canSeek ?? false
                        onPressed:         mouse => { root.seeking = true;  root.seekPreviewFrac = Math.max(0, Math.min(1, mouse.x / seekTrack.width)) }
                        onPositionChanged: mouse => { if (pressed) root.seekPreviewFrac = Math.max(0, Math.min(1, mouse.x / seekTrack.width)) }
                        onReleased:        mouse => { root.player.position = root.seekPreviewFrac * root.length; root.syncPos(); root.seeking = false }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: root.fmtTime(root.seeking ? root.seekPreviewFrac * root.length : root.pos); font.family: Theme.font; font.pixelSize: 11; color: Qt.alpha(Theme.foreground, 0.44) }
                Item { Layout.fillWidth: true }
                Text { text: root.fmtTime(root.length); font.family: Theme.font; font.pixelSize: 11; color: Qt.alpha(Theme.foreground, 0.44) }
            }
        }

        // ── Controls ───────────────────────────────────────────────────
        // Prev/Play/Next are Canvas-drawn for clean geometry.
        // Shuffle/Loop stay as nerd font (complex curved arrows).
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2; Layout.bottomMargin: 20
            spacing: 0

            Text {
                text: "󰒝"
                font.family: Theme.nerdFont; font.pixelSize: 19
                color: (root.player?.shuffle ?? false)
                    ? root.accentColor
                    : Qt.alpha(Theme.foreground, (root.player?.shuffleSupported ?? false) ? 0.48 : 0.18)
                Behavior on color { ColorAnimation { duration: 250 } }
                MouseArea {
                    id: shuffleMo; anchors.fill: parent; anchors.margins: -10
                    enabled: root.player?.shuffleSupported ?? false
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
            }

            Item { implicitWidth: 14 }

            Canvas {
                id: prevIcon
                implicitWidth: 36; implicitHeight: 36
                opacity: (root.player?.canGoPrevious ?? false) ? 1 : 0.22
                Behavior on opacity { NumberAnimation { duration: 200 } }
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const rrect = (x, y, w, h, r) => {
                        c.beginPath(); c.moveTo(x+r,y)
                        c.lineTo(x+w-r,y); c.arcTo(x+w,y,x+w,y+r,r)
                        c.lineTo(x+w,y+h-r); c.arcTo(x+w,y+h,x+w-r,y+h,r)
                        c.lineTo(x+r,y+h); c.arcTo(x,y+h,x,y+h-r,r)
                        c.lineTo(x,y+r); c.arcTo(x,y,x+r,y,r); c.closePath()
                    }
                    const col = Qt.alpha(Theme.foreground, 0.88)
                    c.fillStyle = col; c.strokeStyle = col
                    const s = width, cx = s/2, cy = s/2
                    const bw = s*0.14, bh = s*0.52, barX = cx - s*0.31
                    rrect(barX, cy-bh/2, bw, bh, bw/2); c.fill()
                    const tl = barX+bw+s*0.04, tr = cx+s*0.27, th = s*0.48
                    c.lineJoin = "round"; c.lineWidth = s*0.10
                    c.beginPath(); c.moveTo(tr,cy-th/2); c.lineTo(tl,cy); c.lineTo(tr,cy+th/2); c.closePath()
                    c.fill(); c.stroke()
                }
                MouseArea {
                    id: prevMo; anchors.fill: parent; anchors.margins: -8
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }
            }

            Item { implicitWidth: 18 }

            Canvas {
                id: playIcon
                implicitWidth: 52; implicitHeight: 52
                opacity: (root.player?.canTogglePlaying ?? false) ? 1 : 0.25
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // 0 = play triangle, 1 = pause bars; animates on playing change
                property real morph: root.playing ? 1 : 0
                Behavior on morph { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
                onMorphChanged: requestPaint()

                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const rrect = (x, y, w, h, r) => {
                        c.beginPath(); c.moveTo(x+r,y)
                        c.lineTo(x+w-r,y); c.arcTo(x+w,y,x+w,y+r,r)
                        c.lineTo(x+w,y+h-r); c.arcTo(x+w,y+h,x+w-r,y+h,r)
                        c.lineTo(x+r,y+h); c.arcTo(x,y+h,x,y+h-r,r)
                        c.lineTo(x,y+r); c.arcTo(x,y,x+r,y,r); c.closePath()
                    }
                    const s = width, cx = s/2, cy = s/2
                    const t = playIcon.morph

                    // Play triangle — cross-fades out
                    if (t < 1) {
                          c.globalAlpha = 1 - t
                         c.fillStyle = root.accentColor
                          c.strokeStyle = root.accentColor

                          const offsetX = -s * 0.05 // move left
                          const h = s * 0.42
                          const left = cx - s * 0.10 + offsetX
                          const right = cx + s * 0.22 + offsetX

                          c.lineJoin = "round"
                          c.lineWidth = s * 0.09

                          c.beginPath()
                          c.moveTo(left, cy - h / 2)
                          c.lineTo(right, cy)
                          c.lineTo(left, cy + h / 2)
                          c.closePath()
                          c.fill()
                          c.stroke()
                        // c.globalAlpha = 1 - t
                        // c.fillStyle = root.accentColor; c.strokeStyle = root.accentColor
                        // const h = s*0.52, left = cx-s*0.12, right = cx+s*0.28
                        // c.lineJoin = "round"; c.lineWidth = s*0.11
                        // c.beginPath(); c.moveTo(left,cy-h/2); c.lineTo(right,cy); c.lineTo(left,cy+h/2); c.closePath()
                        // c.fill(); c.stroke()
                    }

                    // Pause bars — cross-fade in
                    if (t > 0) {
                        c.globalAlpha = t
                        c.fillStyle = root.accentColor
                        const bw = s*0.165, bh = s*0.52, gap = s*0.095
                        rrect(cx-gap/2-bw, cy-bh/2, bw, bh, bw/2); c.fill()
                        rrect(cx+gap/2,    cy-bh/2, bw, bh, bw/2); c.fill()
                    }
                }
                Connections {
                    target: root
                    function onAccentColorChanged() { playIcon.requestPaint() }
                }
                MouseArea {
                    id: playMo; anchors.fill: parent; anchors.margins: -8
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }
            }

            Item { implicitWidth: 18 }

            Canvas {
                id: nextIcon
                implicitWidth: 36; implicitHeight: 36
                opacity: (root.player?.canGoNext ?? false) ? 1 : 0.22
                Behavior on opacity { NumberAnimation { duration: 200 } }
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const rrect = (x, y, w, h, r) => {
                        c.beginPath(); c.moveTo(x+r,y)
                        c.lineTo(x+w-r,y); c.arcTo(x+w,y,x+w,y+r,r)
                        c.lineTo(x+w,y+h-r); c.arcTo(x+w,y+h,x+w-r,y+h,r)
                        c.lineTo(x+r,y+h); c.arcTo(x,y+h,x,y+h-r,r)
                        c.lineTo(x,y+r); c.arcTo(x,y,x+r,y,r); c.closePath()
                    }
                    const col = Qt.alpha(Theme.foreground, 0.88)
                    c.fillStyle = col; c.strokeStyle = col
                    const s = width, cx = s/2, cy = s/2
                    const barX = cx+s*0.17, bw = s*0.14, bh = s*0.52
                    const tl = cx-s*0.27, tr = barX-s*0.04, th = s*0.48
                    c.lineJoin = "round"; c.lineWidth = s*0.10
                    c.beginPath(); c.moveTo(tl,cy-th/2); c.lineTo(tr,cy); c.lineTo(tl,cy+th/2); c.closePath()
                    c.fill(); c.stroke()
                    rrect(barX, cy-bh/2, bw, bh, bw/2); c.fill()
                }
                MouseArea {
                    id: nextMo; anchors.fill: parent; anchors.margins: -8
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }

            Item { implicitWidth: 14 }

            Text {
                text: root.player?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                font.family: Theme.nerdFont; font.pixelSize: 19
                color: (root.player !== null && root.player.loopState !== MprisLoopState.None)
                    ? root.accentColor
                    : Qt.alpha(Theme.foreground, (root.player?.loopSupported ?? false) ? 0.48 : 0.18)
                Behavior on color { ColorAnimation { duration: 250 } }
                MouseArea {
                    id: loopMo; anchors.fill: parent; anchors.margins: -10
                    enabled: root.player?.loopSupported ?? false
                    onClicked: {
                        const s = root.player.loopState
                        root.player.loopState = s === MprisLoopState.None     ? MprisLoopState.Playlist
                                              : s === MprisLoopState.Playlist ? MprisLoopState.Track
                                                                              : MprisLoopState.None
                    }
                }
            }
        }
    }
}
