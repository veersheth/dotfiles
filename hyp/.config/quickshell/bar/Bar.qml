import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.notifications
import qs.bar.popups

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root
        required property var modelData
        screen: modelData

        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        exclusiveZone: Theme.barHeight
        color: "transparent"

        WlrLayershell.namespace: "quickshell:bar"

        mask: Region { item: bar }

        Rectangle {
            id: bar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Theme.barHeight
            color: Theme.background

            // Empty bar space → scratchpad. First child, so every module's
            // own MouseArea stays on top and wins input over it.
            MouseArea {
                anchors.fill: parent
                onDoubleClicked: scratchpad.toggle()
            }

            // invisible nub the scratchpad morphs out of
            Item {
                id: scratchAnchor
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                width: 120
                height: parent.height
            }

            ScratchpadPopup {
                id: scratchpad
                anchorItem: scratchAnchor
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: Theme.borderWidth
                color: Theme.barBorder
            }

            // ── Left: workspaces + active window ────────────────────────
            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.moduleSpacing

                Workspaces {
                    monitorName: root.screen?.name ?? ""
                    Layout.alignment: Qt.AlignVCenter
                }

                ActiveWindow {}
            }

            // ── Right: system info ───────────────────────────────────────
            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.moduleSpacing

                Media {}
                Tray {}
                NotificationBell {}
                BluetoothIndicator {}
                WifiIndicator {}
                Clock {}
                Battery {}
            }
        }
    }
}
