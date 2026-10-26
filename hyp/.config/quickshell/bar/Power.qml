import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root
    property color foreground: Theme.foreground
    implicitWidth: Theme.iconSlot
    implicitHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(root.foreground, 0.13)
        opacity: hitArea.containsMouse || menu.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
    }
    Text {
        anchors.centerIn: parent
        text: "󰐥"
        font.family: Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: root.foreground
    }
    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onEntered: tip.show(root)
        onExited: tip.hide()
        onClicked: { tip.hide(); menu.toggle() }
        Accessible.name: "Power menu"
        Accessible.role: Accessible.Button
        Accessible.onPressAction: menu.toggle()
    }
    BarTooltip {
        id: tip
        contentWidth: label.implicitWidth + 24
        contentHeight: label.implicitHeight + 14
        Text {
            id: label
            anchors.centerIn: parent
            text: "Power menu"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.foreground
        }
    }
    PowerPopup { id: menu; anchorItem: root }
}
