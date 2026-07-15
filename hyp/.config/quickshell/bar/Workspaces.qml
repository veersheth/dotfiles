import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root
    property string monitorName: ""

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.pillHeight
    radius: height / 2
    color: Theme.surface
    border.color: Theme.border
    border.width: Theme.borderWidth
    Layout.alignment: Qt.AlignVCenter

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                required property var modelData
                readonly property bool isFocused: modelData.focused

                visible: modelData.monitor?.name === root.monitorName
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: isFocused ? 18 : 6
                implicitHeight: 6
                radius: 3
                color: isFocused
                    ? Qt.alpha(Theme.foreground, 0.85)
                    : wsMouse.containsMouse
                        ? Qt.alpha(Theme.foreground, 0.5)
                        : Qt.alpha(Theme.foreground, 0.22)

                Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                    id: wsMouse
                    anchors { fill: parent; margins: -4 }
                    hoverEnabled: true
                    onClicked: parent.modelData.activate()
                }
            }
        }
    }
}
