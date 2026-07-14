import QtQuick
import qs.common

// MouseArea for bar modules that spills past the visuals to cover the bar's
// full height, so clicks thrown against the screen edge still land (Fitts's
// law). slackX pads the sides; keep it under half the gap to the neighbour.
MouseArea {
    property real slackX: 6

    anchors.fill: parent
    anchors.topMargin:    -(Theme.barHeight - parent.height) / 2
    anchors.bottomMargin: -(Theme.barHeight - parent.height) / 2
    anchors.leftMargin:   -slackX
    anchors.rightMargin:  -slackX
}
