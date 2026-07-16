import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root

    // Sticky player: once a player becomes active, keep it until it disappears,
    // even if it pauses (prevents jumping to another app's player on pause).
    property var _lastPlayer: null

    readonly property var player: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;

        // Prefer a currently-playing player
        for (const p of players)
            if (p.playbackState === MprisPlaybackState.Playing) {
                root._lastPlayer = p;
                return p;
            }

        // Nothing playing — keep the last known player if it's still in the list
        if (root._lastPlayer !== null) {
            for (const p of players)
                if (p === root._lastPlayer) return p;
        }

        // Fallback: first player in list
        root._lastPlayer = players[0];
        return players[0];
    }

    readonly property bool playing:
        player !== null && player.playbackState === MprisPlaybackState.Playing

    // always visible — shows "No media" when no player
    visible: true
    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.player === null ? "󰝚" : root.playing ? "󰏤" : "󰐊"
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize
            color: root.player === null
                ? Qt.alpha(Theme.foreground, 0.35)
                : Theme.foreground
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            elide: Text.ElideRight
            text: {
                if (!root.player) return "No media"
                const artist = root.player.trackArtist;
                const title  = root.player.trackTitle;
                return artist ? `${artist} - ${title}` : title;
            }
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: root.player === null
                ? Qt.alpha(Theme.foreground, 0.35)
                : Theme.foreground
        }
    }

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: hitArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                mediaControls.toggle();
            else if (mouse.button === Qt.MiddleButton && root.player?.canGoNext)
                root.player.next();
        }
    }

    MediaPopup {
        id: mediaControls
        anchorItem: root
        player: root.player
    }
}
