import QtQuick
import qs.common
import qs.components

BarPopup {
    id: root

    required property var player

    signal requestFullscreen()

    contentPadding: 0
    contentWidth:  card.implicitWidth
    contentHeight: card.implicitHeight

    onShownChanged: if (shown) card.syncPos()
    onPlayerChanged: if (!player) close()

    MediaCard {
        id: card
        anchors { left: parent.left; right: parent.right; top: parent.top }
        player: root.player
        active: root.shown
    }

    // Fullscreen expand button — top-right corner overlay
    Rectangle {
        anchors { top: parent.top; right: parent.right; margins: 10 }
        width: 28; height: 28; radius: width / 2
        color: expandMo.containsMouse ? Qt.rgba(1,1,1,0.16) : Qt.rgba(1,1,1,0.08)
        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text: "󰊓"
            font.family: Theme.nerdFont; font.pixelSize: 13
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        MouseArea {
            id: expandMo; anchors.fill: parent; hoverEnabled: true
            onClicked: { root.requestFullscreen(); root.close() }
        }
    }
}
