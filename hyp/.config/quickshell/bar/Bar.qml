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

        anchors.top:    !BarState.barBottom
        anchors.bottom: BarState.barBottom
        anchors.left:   true
        anchors.right:  true
        implicitHeight: Theme.barHeight
        exclusiveZone: Theme.barHeight
        color: "transparent"

        WlrLayershell.namespace: "quickshell:bar"

        mask: Region { item: bar }

        Rectangle {
            id: bar
            anchors {
              top: parent.top; left: parent.left; right: parent.right 

            }
            height: Theme.barHeight
            color: Theme.background

            // Empty bar space → scratchpad (double-click) / context menu (right-click).
            // First child, so every module's own MouseArea stays on top.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onDoubleClicked: scratchpad.toggle()
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const half = barMenu.contentWidth / 2 + 8
                        barMenuAnchor.x = Math.max(half, Math.min(mouse.x, bar.width - half))
                        barMenu.toggle()
                    }
                }
            }

            // invisible nub the scratchpad morphs out of
            Item {
                id: scratchAnchor
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                width: 120
                height: parent.height
            }

            // moves to click x before the menu opens
            Item {
                id: barMenuAnchor
                anchors.top: parent.top
                width: 1; height: parent.height
            }

            ScratchpadPopup {
                id: scratchpad
                anchorItem: scratchAnchor
            }

            BarPopup {
                id: barMenu
                anchorItem: barMenuAnchor
                contentWidth: 246
                contentHeight: barMenuCol.implicitHeight + 32

                Column {
                    id: barMenuCol
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                    spacing: 4

                    Rectangle {
                        width: parent.width; height: 34; radius: 9
                        color: barWallMo.containsMouse ? Theme.hover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 9
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰸉"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Theme.foreground }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Change background…"; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; color: Theme.foreground }
                        }
                        MouseArea { id: barWallMo; anchors.fill: parent; hoverEnabled: true; onClicked: { barMenu.close(); BarState.wallpaperPickerRequested() } }
                    }

                    Rectangle {
                        width: parent.width; height: 34; radius: 9
                        color: barPosMo.containsMouse ? Theme.hover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 9
                            Text { anchors.verticalCenter: parent.verticalCenter; text: BarState.barBottom ? "󰹙" : "󰹘"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Theme.foreground }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: BarState.barBottom ? "Move bar to top" : "Move bar to bottom"; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; color: Theme.foreground }
                        }
                        MouseArea { id: barPosMo; anchors.fill: parent; hoverEnabled: true; onClicked: { barMenu.close(); BarState.setBottom(!BarState.barBottom) } }
                    }
                }
            }

            Rectangle {
                anchors.top:    BarState.barBottom ? parent.top    : undefined
                anchors.bottom: BarState.barBottom ? undefined      : parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: Theme.borderWidth
                color: Theme.barBorder
              }

              Item {
                id: barContents
                anchors {
                  fill: parent
                  leftMargin: 8
                  rightMargin: 8
                  topMargin: 2
                  bottomMargin: 2
                }


                // LEFT
              RowLayout {
                  anchors { left: parent.left; leftMargin: 14; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing

                  Workspaces { monitorName: root.screen?.name ?? ""; Layout.fillHeight: true }

                  ActiveWindow { Layout.fillHeight: true }
              }

              // CENTER
              RowLayout {
                  anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing
              }

              // RIGHT
              RowLayout {
                  anchors { right: parent.right; rightMargin: 14; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing

                  Media { Layout.fillHeight: true }

                  Tray { Layout.fillHeight: true }

                  Caffeine { Layout.fillHeight: true }

                  NotificationBell { Layout.fillHeight: true }

                  QuickSettings { Layout.fillHeight: true }

                  Clock { Layout.fillHeight: true }

                  Battery { Layout.fillHeight: true }
              }
            }
        }
    }
}
