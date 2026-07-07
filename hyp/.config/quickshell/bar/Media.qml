import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.common
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

    visible: player !== null
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.playing ? "󰏤" : "󰐊"
            font.family: Theme.nerdFont
            font.pixelSize: Theme.iconSize
            color: Theme.foreground
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            elide: Text.ElideRight
            text: {
                if (!root.player) return "";
                const artist = root.player.trackArtist;
                const title  = root.player.trackTitle;
                return artist ? `${artist} - ${title}` : title;
            }
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (!root.player) return;
            if (mouse.button === Qt.LeftButton)
                mediaControls.toggle();
            else if (mouse.button === Qt.MiddleButton && root.player.canGoNext)
                root.player.next();
        }
    }

    MediaPopup {
        id: mediaControls
        anchorItem: root
        player: root.player
    }
}
