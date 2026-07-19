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
    color: "transparent"
    // border.color: Theme.border
    // border.width: Theme.borderWidth
    Layout.alignment: Qt.AlignVCenter

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: Hyprland.workspaces

            Item {
                required property var modelData
                readonly property bool isFocused: modelData.focused

                visible: modelData.monitor?.name === root.monitorName
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: label.implicitWidth + 6
                implicitHeight: label.implicitHeight

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData.id
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: parent.isFocused ? Font.SemiBold : Font.Normal
                    color: parent.isFocused
                        ? Theme.blue
                        : wsMouse.containsMouse
                            ? Qt.alpha(Theme.foreground, 0.6)
                            : Qt.alpha(Theme.foreground, 0.3)
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.modelData.activate()
                }
            }
        }
    }
}
