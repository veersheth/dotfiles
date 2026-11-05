import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.wallpaper
import qs.notifications
import qs.bar.popups

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root
        required property var modelData
        screen: modelData
        visible: !BarState.exposeActive

        anchors.top:    !BarState.barBottom
        anchors.bottom: BarState.barBottom
        anchors.left:   true
        anchors.right:  true
        implicitHeight: Theme.barHeight
        exclusiveZone: BarState.exposeActive ? 0 : Theme.barHeight
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:bar"

        mask: Region { item: bar }

        BarContrast {
            id: contrast
            screenWidth: root.screen?.width ?? 1920
            screenHeight: root.screen?.height ?? 1080
        }

        Rectangle {
            id: bar
            anchors {
              top: parent.top; left: parent.left; right: parent.right
            }
            height: Theme.barHeight
            color: BarState.transparent ? "transparent" : Theme.background

            // Empty bar space → context menu (right-click).
            // First child, so every module's own MouseArea stays on top.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const half = barMenu.contentWidth / 2 + 8
                        barMenuAnchor.x = Math.max(half, Math.min(mouse.x, bar.width - half))
                        barMenu.toggle()
                    }
                }
            }

            // moves to click x before the menu opens
            Item {
                id: barMenuAnchor
                anchors.top: parent.top
                width: 1; height: parent.height
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
                        color: transparencyMo.containsMouse ? Theme.hover : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: BarState.transparent ? "✓  Transparent bar" : "Transparent bar"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: Theme.foreground
                        }
                        MouseArea {
                            id: transparencyMo
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { BarState.setTransparent(!BarState.transparent); barMenu.close() }
                        }
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
                color: BarState.transparent ? "transparent" : Theme.barBorder
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

                  Workspaces { id: workspaces; foreground: contrast.foreground; monitorName: root.screen?.name ?? ""; Layout.fillHeight: true }

                  // Media { Layout.fillHeight: true }

                  ActiveWindow {
                      foreground: contrast.foreground
                      maximumWidth: Math.max(0, Math.min(320, barContents.width - workspaces.implicitWidth - rightModules.implicitWidth - 60))
                      Layout.leftMargin: 8
                      Layout.fillHeight: true
                  }
              }

              // CENTER
              RowLayout {
                  anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing

                  // Clock { foreground: contrast.foreground; Layout.fillHeight: true }

              }

              // RIGHT
              StatusModules {
                  id: rightModules
                  anchors { right: parent.right; rightMargin: 14; top: parent.top; bottom: parent.bottom }
                  foreground: contrast.foreground
              }
            }
        }
    }
}
