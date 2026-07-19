import QtQuick
import qs.common

// Bare track + thumb slider used by all volume/brightness/seek controls.
// Set value/maxValue/fillColor from outside; handle onMoved/onReleased.
// tickAt > 0 draws a tick mark at that value (e.g. tickAt:1.0 for 100% on a 0–1.5 range).
Item {
    id: root

    property real  value:       0
    property real  maxValue:    1.0
    property real  tickAt:      0.0
    property color fillColor:   Theme.blue
    property bool  interactive: true

    signal pressed()
    signal moved(real v)
    signal released(real v)

    implicitWidth:  Theme.sliderWidth
    implicitHeight: 20

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 4; radius: 2
        color: Qt.alpha(Theme.foreground, 0.12)

        Rectangle {
            visible: root.tickAt > 0 && root.maxValue > 0
            x: parent.width * (root.tickAt / root.maxValue) - 1
            width: 2; height: parent.height * 2.5
            anchors.verticalCenter: parent.verticalCenter
            radius: 1
            color: Qt.alpha(Theme.foreground, 0.28)
        }

        Rectangle {
            width: root.maxValue > 0
                ? Math.max(0, Math.min(1, root.value / root.maxValue)) * parent.width : 0
            height: parent.height; radius: 2; color: root.fillColor
            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            x: root.maxValue > 0
                ? Math.max(0, Math.min(track.width - width,
                    (root.value / root.maxValue) * track.width - width / 2)) : 0
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7; color: "white"; z: 1
            scale: dragArea.containsMouse || dragArea.pressed ? 1 : 0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
        }

        MouseArea {
            id: dragArea
            anchors { fill: parent; margins: -8 }
            hoverEnabled: true
            enabled: root.interactive

            function valueAt(mx) {
                return Math.max(0, Math.min(root.maxValue, (mx / track.width) * root.maxValue))
            }

            onPressed: mouse => {
                root.pressed()
                root.moved(valueAt(mouse.x))
            }
            onPositionChanged: mouse => {
                if (pressed) root.moved(valueAt(mouse.x))
            }
            onReleased: mouse => root.released(valueAt(mouse.x))
        }
    }
}
