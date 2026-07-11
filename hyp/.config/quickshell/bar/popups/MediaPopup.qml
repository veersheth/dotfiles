import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    required property var player

    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property real length:  player?.length ?? 0

    property real pos:             0
    property bool seeking:         false
    property real seekPreviewFrac: 0
    readonly property real seekFrac: seeking
        ? seekPreviewFrac
        : (length > 0 ? Math.min(1, pos / length) : 0)

    property color accentColor: Theme.blue
    Behavior on accentColor { ColorAnimation { duration: 500 } }

    readonly property string artUrl: player?.trackArtUrl ?? ""
    property string _slotA: ""
    property string _slotB: ""
    property bool   _useA:  true

    contentWidth:  300
    contentHeight: col.implicitHeight + 2

    Component.onCompleted: { _slotA = artUrl; colorExtract.extract(artUrl); }

    onArtUrlChanged: {
        if (_useA) { _slotB = artUrl; _useA = false; }
        else       { _slotA = artUrl; _useA = true;  }
        colorExtract.extract(artUrl);
    }

    onShownChanged: if (shown) syncPos()
    onPlayerChanged: if (!player) close()

    function syncPos() { pos = player?.position ?? 0 }
    function fmtTime(s) {
        s = Math.max(0, Math.round(s));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.visible && root.player !== null && !root.seeking
        onTriggered: root.syncPos()
    }

    // ── Dominant colour extractor ──────────────────────────────────────
    Canvas {
        id: colorExtract
        width: 24; height: 24; visible: false
        property string pending: ""

        function extract(url) {
            if (!url) { root.accentColor = Theme.blue; return; }
            pending = url; loadImage(url);
        }

        onImageLoaded: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(pending, 0, 0, width, height);
            const d = ctx.getImageData(0, 0, width, height).data;
            let r = 0, g = 0, b = 0;
            const n = d.length / 4;
            for (let i = 0; i < d.length; i += 4) { r += d[i]; g += d[i+1]; b += d[i+2]; }
            r /= n; g /= n; b /= n;
            const lum = r * 0.299 + g * 0.587 + b * 0.114;
            const sat = 2.4;
            r = Math.min(255, Math.max(0, lum + (r - lum) * sat));
            g = Math.min(255, Math.max(0, lum + (g - lum) * sat));
            b = Math.min(255, Math.max(0, lum + (b - lum) * sat));
            const peak = Math.max(r, g, b);
            if (peak < 130) { const f = 160 / Math.max(1, peak); r = Math.min(255, r*f); g = Math.min(255, g*f); b = Math.min(255, b*f); }
            root.accentColor = Qt.rgba(r / 255, g / 255, b / 255, 1);
        }
    }

    // ── Control button ─────────────────────────────────────────────────
    component ControlBtn: Rectangle {
        id: btn
        property alias icon: lbl.text
        property bool  active: false
        signal activated()

        implicitWidth: 36; implicitHeight: 36
        radius: width / 2
        color: mo.containsMouse && enabled ? Theme.hover : "transparent"

        Text {
            id: lbl
            anchors.centerIn: parent
            font.family:    Theme.nerdFont
            font.pixelSize: 17
            color: btn.active ? root.accentColor
                 : Qt.alpha(Theme.foreground, btn.enabled ? 1 : 0.3)
            Behavior on color { ColorAnimation { duration: 400 } }
        }
        MouseArea { id: mo; anchors.fill: parent; hoverEnabled: true; onClicked: btn.activated() }
    }

    // ── Layout ─────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        // ── Vinyl record ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 234
            clip: true

            Rectangle {
                anchors.centerIn: vinyl
                width: vinyl.width + 36; height: width; radius: width / 2
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.09)
                z: -1
            }
            Rectangle {
                anchors.centerIn: vinyl
                width: vinyl.width + 18; height: width; radius: width / 2
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                z: -1
            }

            // The record itself
            Item {
                id: vinyl
                width: 196; height: 196
                anchors.centerIn: parent

                // Album art — circular clip with crossfade
                ClippingRectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#0d0d0d"

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

                        // Edge vignette
                        const vgn = ctx.createRadialGradient(cx, cy, r * 0.55, cx, cy, r);
                        vgn.addColorStop(0, "rgba(0,0,0,0)");
                        vgn.addColorStop(1, "rgba(0,0,0,0.60)");
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.fillStyle = vgn; ctx.fill();

                        // Grooves
                        for (let ri = 32; ri < r - 6; ri += 8) {
                            ctx.beginPath(); ctx.arc(cx, cy, ri, 0, Math.PI * 2);
                            ctx.strokeStyle = "rgba(0,0,0,0.20)";
                            ctx.lineWidth = 1.2; ctx.stroke();
                        }

                        // Center label
                        const lbl = ctx.createRadialGradient(cx, cy, 0, cx, cy, 30);
                        lbl.addColorStop(0, "rgba(0,0,0,0.72)");
                        lbl.addColorStop(1, "rgba(0,0,0,0.52)");
                        ctx.beginPath(); ctx.arc(cx, cy, 30, 0, Math.PI * 2);
                        ctx.fillStyle = lbl; ctx.fill();

                        // Spindle
                        ctx.beginPath(); ctx.arc(cx, cy, 4.5, 0, Math.PI * 2);
                        ctx.fillStyle = "rgba(255,255,255,0.18)"; ctx.fill();
                    }
                }

                // Timer keeps vinyl.rotation as a plain value that survives stop/start,
                // unlike RotationAnimator which resets to `from` when running toggles.
                Timer {
                    interval: 16
                    repeat: true
                    running: root.playing && root.visible
                    onTriggered: vinyl.rotation = (vinyl.rotation + 360 * 16 / 9000) % 360
                }
            }

            // Placeholder icon when no art
            Text {
                anchors.centerIn: vinyl
                visible: !root.artUrl
                text: "󰝚"
                font.family: Theme.nerdFont; font.pixelSize: 52
                color: Qt.alpha(Theme.foreground, 0.15)
            }
        }

        // ── Title: scrolling marquee ───────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.topMargin:   14
            Layout.leftMargin:  18
            Layout.rightMargin: 18
            implicitHeight: titleText.implicitHeight
            clip: true

            Text {
                id: titleText
                text: root.player?.trackTitle || "Nothing playing"
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
                    PauseAnimation  { duration: 1500 }
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
            Layout.fillWidth: true; Layout.topMargin: 16; visible: root.length > 0
            Layout.leftMargin: 18; Layout.rightMargin: 18; spacing: 6

            Item {
                Layout.fillWidth: true; implicitHeight: 20

                Rectangle {
                    id: seekTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 4; radius: 2
                    color: Qt.alpha(Theme.foreground, 0.12)

                    Rectangle {
                        id: seekFill
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
                        id: seekThumb
                        parent: seekTrack
                        x: Math.max(0, Math.min(seekTrack.width - width, seekFill.width - width / 2))
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
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14; Layout.bottomMargin: 18
            spacing: 6

            ControlBtn { icon: "󰒝"; enabled: root.player?.shuffleSupported ?? false; active: root.player?.shuffle ?? false; onActivated: root.player.shuffle = !root.player.shuffle }
            ControlBtn { icon: "󰒮"; enabled: root.player?.canGoPrevious ?? false; onActivated: root.player.previous() }

            Rectangle {
                implicitWidth: 52; implicitHeight: 52; radius: 26
                color: playMo.containsMouse ? Qt.lighter(root.accentColor, 1.15) : root.accentColor
                opacity: (root.player?.canTogglePlaying ?? false) ? 1 : 0.4
                Text { anchors.centerIn: parent; text: root.playing ? "󰏤" : "󰐊"; font.family: Theme.nerdFont; font.pixelSize: 22; color: "white" }
                MouseArea { id: playMo; anchors.fill: parent; hoverEnabled: true; enabled: root.player?.canTogglePlaying ?? false; onClicked: root.player.togglePlaying() }
            }

            ControlBtn { icon: "󰒭"; enabled: root.player?.canGoNext ?? false; onActivated: root.player.next() }
            ControlBtn {
                icon: root.player?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                enabled: root.player?.loopSupported ?? false
                active: root.player !== null && root.player.loopState !== MprisLoopState.None
                onActivated: {
                    const s = root.player.loopState;
                    root.player.loopState = s === MprisLoopState.None     ? MprisLoopState.Playlist
                                          : s === MprisLoopState.Playlist ? MprisLoopState.Track
                                                                           : MprisLoopState.None;
                }
            }
        }
    }
}
