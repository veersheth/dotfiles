import QtQuick
import qs.common
import qs.components

BarPopup {
    id: root

    required property var player

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
}
