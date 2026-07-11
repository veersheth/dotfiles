import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.common

RowLayout {
    id: root
    spacing: 10

    property string monitorName: ""

    Repeater {
        model: Hyprland.workspaces

        Text {
            required property var modelData
            readonly property bool isFocused: modelData.focused

            visible: modelData.monitor?.name === root.monitorName

            Layout.alignment: Qt.AlignVCenter
            text: modelData.id
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: isFocused ? Font.Bold : Font.Normal
            color: isFocused
                ? Theme.blue
                : mouse.containsMouse
                    ? Qt.alpha(Theme.foreground, 0.7)
                    : Qt.alpha(Theme.foreground, 0.35)

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                onClicked: Hyprland.dispatch(`workspace ${parent.modelData.id}`)
            }
        }
    }
}
