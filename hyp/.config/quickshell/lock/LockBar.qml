import QtQuick
import qs.common
import qs.bar

// The same desktop status modules, shown without interaction on the lock surface.
Item {
    id: root
    width: parent.width
    height: Theme.barHeight
    anchors.top: BarState.barBottom ? undefined : parent.top
    anchors.bottom: BarState.barBottom ? parent.bottom : undefined

    BarContrast {
        id: contrast
        screenWidth: root.width
        screenHeight: root.parent?.height ?? 1080
    }

    Rectangle {
        anchors.fill: parent
        color: BarState.transparent ? "transparent" : Theme.background

        Rectangle {
            height: Theme.borderWidth
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: BarState.barBottom ? undefined : parent.bottom
            anchors.top: BarState.barBottom ? parent.top : undefined
            color: BarState.transparent ? "transparent" : Theme.barBorder
        }
    }

    StatusModules {
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        foreground: contrast.foreground
        locked: true
    }
}
