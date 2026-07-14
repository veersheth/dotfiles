import QtQuick
import QtQuick.Layouts
import qs.common

// A rounded "island" that modules sit inside.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int hPadding: 10
    property bool clickable: false
    signal clicked()

    implicitWidth: row.implicitWidth + hPadding * 2
    implicitHeight: Theme.pillHeight
    radius: height / 2
    color: Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.border


    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.hover
        opacity: hitArea.containsMouse && root.clickable ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    BarHitArea {
        id: hitArea
        enabled: root.clickable
        hoverEnabled: root.clickable
        onClicked: root.clicked()
    }
}
