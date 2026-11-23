import QtQuick
import qs.common

// One row in the shared shell context menu.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool checked: false
    property bool checkable: false

    signal triggered()

    width: parent.width
    height: 34
    radius: 9
    color: rowMo.containsMouse ? Theme.hover : "transparent"

    Row {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 9

        Text {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.checkable ? (root.checked ? "✓" : " ") : root.icon
            font.family: root.checkable ? Theme.font : Theme.nerdFont
            font.pixelSize: root.checkable ? Theme.fontSize : Theme.iconSize
            font.weight: root.checkable ? Font.DemiBold : Font.Normal
            color: Theme.foreground
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    MouseArea {
        id: rowMo
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.triggered()
    }
}
