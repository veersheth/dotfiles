import QtQuick
import qs.common

// Pill-shaped on/off toggle. Bind `checked`; handle `toggled()` to act.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.blue : Qt.alpha(Theme.foreground, 0.18)
    Behavior on color { ColorAnimation { duration: 160 } }

    Rectangle {
        width: 16; height: 16; radius: width / 2
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}
