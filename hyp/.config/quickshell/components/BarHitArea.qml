import QtQuick
import qs.common

// MouseArea for bar modules that spills past the visuals to cover the bar's
// full height, so clicks thrown against the screen edge still land (Fitts's
// law). slackX pads the sides; keep it under half the gap to the neighbour.
MouseArea {
    id: root
    property real slackX: 6

    x: -slackX
    width: parent.width + 2 * slackX
    height: Theme.barHeight
    anchors.verticalCenter: parent.verticalCenter

    // Use Connections so module-specific onEntered/onExited handlers cannot
    // replace this hover tracking.
    Connections {
        target: root
        function onEntered() { if (root.hoverEnabled) BarHover.enter() }
        function onExited() { if (root.hoverEnabled) BarHover.leave() }
    }
}
