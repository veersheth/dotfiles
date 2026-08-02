import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Fullscreen media player with synced lyrics.
// Skeuomorphic dark-metal chassis — album art left, LCD lyrics right.
// Lyrics only fetched from LRCLIB when this surface is visible.
PanelWindow {
    id: root

    property var  player: null
    property bool shown:  false

    function open()  { shown = true  }
    function close() { shown = false }

    readonly property bool playing:
        player !== null && player.playbackState === MprisPlaybackState.Playing

    // ── Accent color (extracted from album art) ───────────────────────────
    property color accentColor: "#a7b8dd"
    Behavior on accentColor { ColorAnimation { duration: 900 } }

    ColorQuantizer {
        id: colorQuant
        depth: 2
        onColorsChanged: if (colors.length > 0) root.accentColor = colors[0]
    }

    // ── Dual-slot album art with cross-fade ───────────────────────────────
    property string artUrl: player?.trackArtUrl ?? ""
    property string _slotA: ""; property string _slotB: ""; property bool _useA: true

    onArtUrlChanged: {
        if (_useA) { _slotB = artUrl; _useA = false } else { _slotA = artUrl; _useA = true }
        colorQuant.source = artUrl
    }
    Component.onCompleted: { _slotA = artUrl; colorQuant.source = artUrl }

    // ── Seek position (local interpolation) ───────────────────────────────
    property real seekPos:        0       // seconds, local tracker
    property real lyricsPos:      0       // seconds, local tracker
    property bool seeking:        false
    property real seekPreviewFrac: 0
    property var  _lastSyncAt:    0

    readonly property real length:   player?.length ?? 0
    readonly property real seekFrac: seeking ? seekPreviewFrac
        : (length > 0 ? Math.min(1, seekPos / length) : 0)

    function _syncPos() {
        const p = player?.position ?? 0
        seekPos = p; lyricsPos = p; _lastSyncAt = Date.now()
    }
    function fmtTime(s) {
        s = Math.max(0, Math.round(s))
        return `${Math.floor(s/60)}:${String(s%60).padStart(2,"0")}`
    }

    // ── Volume (Pipewire) ─────────────────────────────────────────────────
    readonly property real  sinkVol:   Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool  sinkMuted: Pipewire.defaultAudioSink?.audio?.muted  ?? false

    // ── Lyrics state ──────────────────────────────────────────────────────
    property var    lyricsLines:    []
    property string plainLyrics:    ""
    property int    currentLineIdx: -1
    property string lyricsStatus:   ""   // "loading" | "none" | "plain" | "" (synced ok)
    property string _fetchedTitle:  ""

    // ── Window ────────────────────────────────────────────────────────────
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace:     "quickshell:media-fullscreen"
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        if (shown) {
            overlay.opacity = 0; visible = true
            enterAnim.restart(); _syncPos(); _fetchLyrics()
        } else {
            enterAnim.stop(); exitAnim.restart()
            lrcFetch.running = false
            _fetchedTitle = ""; lyricsLines = []; plainLyrics = ""
            lyricsStatus = ""; currentLineIdx = -1
        }
    }

    Shortcut { sequence: "Escape"; enabled: root.shown; onActivated: root.close() }

    NumberAnimation    { id: enterAnim; target: overlay; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation { target: overlay; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
        ScriptAction    { script: root.visible = false }
    }

    // ── Timers ────────────────────────────────────────────────────────────
    Timer {
        interval: 250; repeat: true
        running: root.shown && root.player !== null
        onTriggered: {
            if (root.playing && !root.seeking) { root.seekPos += 0.25; root.lyricsPos += 0.25 }
            if (Date.now() - root._lastSyncAt > 5000) root._syncPos()
            if (root.lyricsLines.length > 0) {
                const ms = root.lyricsPos * 1000
                let idx = 0
                for (let i = 0; i < root.lyricsLines.length; i++) {
                    if (root.lyricsLines[i].time <= ms) idx = i; else break
                }
                if (idx !== root.currentLineIdx) root.currentLineIdx = idx
            }
        }
    }

    Connections {
        target: root.player; enabled: root.shown && root.player !== null
        function onTrackTitleChanged() { root._fetchedTitle = ""; root._syncPos(); root._fetchLyrics() }
    }

    // ── Lyrics fetch ──────────────────────────────────────────────────────
    function _fetchLyrics() {
        const p = root.player; if (!p) return
        const title = p.trackTitle ?? ""; if (!title || title === root._fetchedTitle) return
        root._fetchedTitle = title; root.lyricsLines = []; root.plainLyrics = ""
        root.lyricsStatus = "loading"; root.currentLineIdx = -1
        const url = "https://lrclib.net/api/get"
            + "?track_name="  + encodeURIComponent(title)
            + "&artist_name=" + encodeURIComponent(p.trackArtist ?? "")
            + "&album_name="  + encodeURIComponent(p.trackAlbum  ?? "")
            + "&duration="    + Math.round(p.length ?? 0)
        lrcFetch.command = ["curl", "-sf", "--max-time", "8", url]
        lrcFetch.running = true
    }
    function _parseLrc(text) {
        const out = []
        for (const line of text.split("\n")) {
            const m = line.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)/)
            if (!m) continue
            const ms = (parseInt(m[1]) * 60 + parseFloat(m[2])) * 1000
            const t  = m[3].trim()
            if (t) out.push({ time: ms, text: t })
        }
        return out.sort((a, b) => a.time - b.time)
    }
    Process {
        id: lrcFetch
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw.startsWith("curl:")) { root.lyricsStatus = "none"; return }
                try {
                    const obj = JSON.parse(raw)
                    if (obj.syncedLyrics) {
                        root.lyricsLines = root._parseLrc(obj.syncedLyrics)
                        root.lyricsStatus = root.lyricsLines.length > 0 ? "" : "none"
                    } else if (obj.plainLyrics) {
                        root.plainLyrics = obj.plainLyrics.trim()
                        root.lyricsStatus = "plain"
                    } else { root.lyricsStatus = "none" }
                } catch (_) { root.lyricsStatus = "none" }
            }
        }
        stderr: StdioCollector {}
    }


    // ════════════════════════════════════════════════════════════════════
    // UI
    // ════════════════════════════════════════════════════════════════════
    Item {
        id: overlay
        anchors.fill: parent
        opacity: 0

        // ── Very dark background (album art as faint blurred tint) ────────
        Rectangle {
            anchors.fill: parent
            color: "#0c0c0e"

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(80, 80)
                smooth: true; asynchronous: true; opacity: 0.06
            }
        }

        // ── Close button (system-styled pill) ────────────────────────────
        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: 20 }
            width: 32; height: 32; radius: 16
            color: closeMo.containsMouse ? Theme.hoverStrong : Theme.hover
            Behavior on color { ColorAnimation { duration: 80 } }
            Text {
                anchors.centerIn: parent; text: "󰅖"
                font.family: Theme.nerdFont; font.pixelSize: 14
                color: Qt.alpha(Theme.foreground, 0.60)
            }
            MouseArea { id: closeMo; anchors.fill: parent; hoverEnabled: true; onClicked: root.close() }
        }

        // ── Two-panel layout ──────────────────────────────────────────────
        Item {
            anchors { fill: parent; leftMargin: 60; rightMargin: 60; topMargin: 48; bottomMargin: 48 }

            // ══════════ LEFT: system-design player ══════════════════════
            Item {
                id: leftPanel
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 320

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 0

                    MediaCard {
                        Layout.fillWidth: true
                        player: root.player
                        active: root.shown
                    }

                    // Volume row — identical style to VolumePopup
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: volIconMo.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }
                            Text {
                                anchors.centerIn: parent
                                text: root.sinkMuted          ? "󰝟"
                                    : root.sinkVol < 0.33    ? "󰕿"
                                    : root.sinkVol < 0.66    ? "󰖀" : "󰕾"
                                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                                color: root.sinkMuted ? Qt.alpha(Theme.foreground, 0.40) : Theme.foreground
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                            MouseArea {
                                id: volIconMo; anchors.fill: parent; hoverEnabled: true
                                onClicked: if (Pipewire.defaultAudioSink?.audio)
                                    Pipewire.defaultAudioSink.audio.muted = !root.sinkMuted
                            }
                        }

                        CommonSlider {
                            Layout.fillWidth: true
                            value: root.sinkVol; maxValue: 1.5; tickAt: 1.0
                            fillColor: root.sinkMuted      ? Qt.alpha(Theme.foreground, 0.28)
                                     : root.sinkVol > 1.0 ? Theme.yellow
                                     : Theme.blue
                            onMoved: v => { if (Pipewire.defaultAudioSink?.audio)
                                Pipewire.defaultAudioSink.audio.volume = v }
                        }

                        Text {
                            text: `${Math.round(root.sinkVol * 100)}%`
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Medium
                            color: root.sinkVol > 1.0 ? Theme.yellow : Qt.alpha(Theme.foreground, 0.70)
                            Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // ══════════ RIGHT: CRT monitor ═══════════════════════════════
            Item {
                anchors { left: leftPanel.right; leftMargin: 48; right: parent.right; top: parent.top; bottom: parent.bottom }

                // Ambient phosphor glow behind the whole monitor
                Rectangle {
                    anchors { fill: crtBezel; margins: -16 }
                    radius: crtBezel.radius + 16
                    color: Qt.rgba(0.04, 0.55, 0.18, 0.12)
                    z: -1
                }

                // CRT plastic bezel
                Rectangle {
                    id: crtBezel
                    anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
                    radius: 22
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#232323" }
                        GradientStop { position: 0.5; color: "#1c1c1c" }
                        GradientStop { position: 1.0; color: "#141414" }
                    }
                    border.color: "#2e2e2e"; border.width: 2

                    // Bezel top highlight
                    Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
                        height: 1; color: Qt.rgba(1,1,1,0.10); radius: parent.radius }
                    // Bezel bottom shadow
                    Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 1 }
                        height: 1; color: Qt.rgba(0,0,0,0.55); radius: parent.radius }

                    // Brand indent — subtle engraved text on the bezel bottom
                    Text {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 12 }
                        text: "PHOSPHOR-1"
                        font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 2.5
                        color: "#2a2a2a"
                        style: Text.Sunken; styleColor: Qt.rgba(1,1,1,0.06)
                    }

                    // Screen surface (the dark phosphor area)
                    Rectangle {
                        id: crtScreen
                        anchors { fill: parent; margins: 14; bottomMargin: 30 }
                        radius: 10
                        color: "#010e04"   // deep dark green-black
                        border.color: "#020f05"; border.width: 1
                        clip: true

                        // ── Status line ───────────────────────────────────
                        Text {
                            anchors { top: parent.top; left: parent.left; margins: 14 }
                            text: root.lyricsStatus === "loading" ? "SEARCHING..." : "LYRICS"
                            font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 3
                            color: "#1a5c28"
                            Behavior on text { }
                        }

                        // ── Lyrics content ────────────────────────────────
                        Item {
                            anchors { fill: parent; topMargin: 30; margins: 20 }

                            // Loading — blinking cursor
                            Text {
                                anchors.centerIn: parent
                                visible: root.lyricsStatus === "loading"
                                text: "█"
                                font.family: Theme.font; font.pixelSize: 18
                                color: "#22aa44"
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite; running: root.lyricsStatus === "loading"
                                    NumberAnimation { to: 0; duration: 500 }
                                    NumberAnimation { to: 1; duration: 500 }
                                }
                            }

                            // Not found
                            Text {
                                anchors.centerIn: parent
                                visible: root.lyricsStatus === "none"
                                text: "NO SIGNAL"
                                font.family: Theme.font; font.pixelSize: 16; font.letterSpacing: 4
                                color: "#0d3318"
                            }

                            // Plain (unsynced)
                            Flickable {
                                anchors.fill: parent
                                visible: root.lyricsStatus === "plain"
                                contentHeight: plainText.implicitHeight
                                clip: true; boundsBehavior: Flickable.StopAtBounds
                                Text {
                                    id: plainText; width: parent.width
                                    text: root.plainLyrics
                                    font.family: Theme.font; font.pixelSize: 16
                                    color: "#33bb55"; wrapMode: Text.Wrap
                                    lineHeight: 1.8; horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Synced — scrolling list with phosphor highlighting
                            Item {
                                anchors.fill: parent
                                visible: root.lyricsStatus === ""

                                ListView {
                                    id: lyricsList
                                    anchors.fill: parent
                                    model: root.lyricsLines; clip: true; spacing: 2
                                    boundsBehavior: Flickable.StopAtBounds
                                    preferredHighlightBegin: height * 0.38
                                    preferredHighlightEnd:   height * 0.62
                                    highlightRangeMode:  ListView.StrictlyEnforceRange
                                    highlightMoveDuration: 500
                                    currentIndex: root.currentLineIdx
                                    highlight: Item {}

                                    delegate: Item {
                                        id: lyricLine
                                        required property var modelData
                                        required property int index
                                        readonly property int  dist:      Math.abs(index - root.currentLineIdx)
                                        readonly property bool isCurrent: index === root.currentLineIdx
                                        width: lyricsList.width
                                        height: lineText.implicitHeight + 26

                                        // Phosphor bloom behind current line
                                        Rectangle {
                                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                            height: lineText.implicitHeight + 14
                                            radius: 4
                                            color: Qt.rgba(0.05, 0.7, 0.2, lyricLine.isCurrent ? 0.10 : 0)
                                            Behavior on color { ColorAnimation { duration: 280 } }
                                        }

                                        Text {
                                            id: lineText
                                            anchors {
                                                left: parent.left; right: parent.right
                                                leftMargin: 16; rightMargin: 16
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: lyricLine.modelData.text
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.Wrap
                                            font.family: Theme.font
                                            font.pixelSize: lyricLine.isCurrent ? 21
                                                          : lyricLine.dist === 1 ? 17 : 14
                                            font.weight: lyricLine.isCurrent ? Font.DemiBold : Font.Normal
                                            // Phosphor green: bright current → dim far lines
                                            color: lyricLine.isCurrent
                                                ? "#3dff6e"
                                                : lyricLine.dist === 1 ? "#1a7a32"
                                                : lyricLine.dist === 2 ? "#0d4020"
                                                : "#071a0d"
                                            Behavior on font.pixelSize { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on color          { ColorAnimation  { duration: 280 } }
                                        }
                                    }
                                }

                                // Edge fades matching screen colour
                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; right: parent.right }
                                    height: 60; z: 1
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#010e04" }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height: 60; z: 1
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: "#010e04" }
                                    }
                                }
                            }
                        }

                        // ── Scanlines overlay ─────────────────────────────
                        Canvas {
                            anchors.fill: parent; z: 10; opacity: 0.22
                            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.fillStyle = "rgba(0,0,0,1)"
                                for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
                            }
                        }

                        // ── Corner vignette (CRT spherical curvature) ─────
                        // Horizontal darkening at left/right edges
                        Rectangle {
                            anchors.fill: parent; z: 11
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.00; color: Qt.rgba(0,0,0,0.50) }
                                GradientStop { position: 0.07; color: "transparent" }
                                GradientStop { position: 0.93; color: "transparent" }
                                GradientStop { position: 1.00; color: Qt.rgba(0,0,0,0.50) }
                            }
                        }
                        // Vertical darkening at top/bottom edges
                        Rectangle {
                            anchors.fill: parent; z: 11
                            gradient: Gradient {
                                GradientStop { position: 0.00; color: Qt.rgba(0,0,0,0.40) }
                                GradientStop { position: 0.06; color: "transparent" }
                                GradientStop { position: 0.94; color: "transparent" }
                                GradientStop { position: 1.00; color: Qt.rgba(0,0,0,0.40) }
                            }
                        }

                        // ── Glass reflection (top-left glare) ────────────
                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height * 0.35; z: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.035) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }
    }
}
