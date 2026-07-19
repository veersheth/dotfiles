import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    signal escaped()
    onEscaped: close()

    contentWidth:  Theme.listWidth + 2 * contentPadding
    contentHeight: col.implicitHeight + 2 * contentPadding

    readonly property var audioSources: Pipewire.nodes.values.filter(n => n.isSource && !n.isStream)
    PwObjectTracker { objects: root.audioSources }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.escaped()
    }

    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4; Layout.rightMargin: 2; Layout.bottomMargin: 4
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30; height: 30; radius: width / 2
                color: backMo.containsMouse ? Theme.hover : "transparent"
                Text { anchors.centerIn: parent; text: "󰅁"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Qt.alpha(Theme.foreground, 0.7) }
                MouseArea { id: backMo; anchors.fill: parent; hoverEnabled: true; onClicked: root.escaped() }
            }

            Text {
                text: "Input"
                font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
                color: Theme.foreground
            }

            Item { Layout.fillWidth: true }
        }

        CommonList {
            Layout.fillWidth: true

            Repeater {
                model: root.audioSources
                delegate: Rectangle {
                    id: srcRow
                    required property var modelData
                    readonly property bool active: Pipewire.defaultAudioSource?.id === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 36; radius: Theme.itemRadius
                    color: active              ? Qt.alpha(Theme.blue, 0.18)
                         : srcMo.containsMouse ? Theme.hover
                         : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 10

                        Text {
                            text: "󰄬"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                            color: Theme.blue; opacity: srcRow.active ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Layout.preferredWidth: 14
                        }

                        Text {
                            Layout.fillWidth: true; elide: Text.ElideRight
                            text: modelData.description || modelData.name
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            font.weight: srcRow.active ? Font.DemiBold : Font.Medium
                            color: Theme.foreground
                        }
                    }

                    MouseArea {
                        id: srcMo; anchors.fill: parent; hoverEnabled: true
                        onClicked: Pipewire.preferredDefaultAudioSource = srcRow.modelData
                    }
                }
            }

            Text {
                visible: root.audioSources.length === 0
                Layout.fillWidth: true; topPadding: 4; leftPadding: 4
                text: "No input devices"
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                color: Qt.alpha(Theme.foreground, 0.45)
            }
        }
    }
}
