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

        mask: Region { item: bar._hidden ? triggerStrip : bar }

        // 2 px strip at the screen edge so hover can re-peek the bar when hidden.
        Item {
            id: triggerStrip
            anchors.top:    !BarState.barBottom ? parent.top    : undefined
            anchors.bottom:  BarState.barBottom ? parent.bottom : undefined
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 2

            HoverHandler {
                onHoveredChanged: {
                    if (hovered && bar._hidden) {
                        bar._peeking = true
                        peekHideTimer.stop()
                    }
                }
            }
        }

        // Auto-hide: hide after the bar loses hover.
        Timer {
            id: peekHideTimer
            interval: 700
            onTriggered: if (bar.autoHide) bar._peeking = false
        }

        Rectangle {
            id: bar
            anchors {
              top: parent.top; left: parent.left; right: parent.right
            }
            height: Theme.barHeight
            color: Theme.background

            // Auto-hide state.
            property bool autoHide: false
            // Temporarily revealed by hovering the edge strip or the bar itself.
            property bool _peeking: false
            readonly property bool _hidden: autoHide && !_peeking

            // Slide off-screen via transform so anchors aren't disturbed.
            property real _slideY: _hidden ? (BarState.barBottom ? Theme.barHeight : -Theme.barHeight) : 0
            Behavior on _slideY { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            transform: Translate { y: bar._slideY }

            HoverHandler {
                id: barHover
                onHoveredChanged: {
                    if (hovered && bar.autoHide) {
                        bar._peeking = true
                        peekHideTimer.stop()
                    } else if (!hovered && bar.autoHide) {
                        peekHideTimer.restart()
                    }
                }
            }

            // Hot corner — hover the leftmost corner square to open the scratchpad.
            Item {
                anchors { left: parent.left; top: parent.top }
                width: 20; height: parent.height
                z: 10

                HoverHandler {
                    id: hotCornerHover
                    onHoveredChanged: if (hovered) hotCornerTimer.restart(); else hotCornerTimer.stop()
                }
                Timer {
                    id: hotCornerTimer
                    interval: 500   // must hover intentionally for half a second
                    onTriggered: if (hotCornerHover.hovered && !scratchpad.shown) scratchpad.shown = true
                }
            }

            // Empty bar space → focus-dim (double-click) / context menu (right-click).
            // First child, so every module's own MouseArea stays on top.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onDoubleClicked: {
                    bar.autoHide = !bar.autoHide
                    // Leaving auto-hide mode: ensure bar is visible immediately.
                    if (!bar.autoHide) bar._peeking = false
                }
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const half = barMenu.contentWidth / 2 + 8
                        barMenuAnchor.x = Math.max(half, Math.min(mouse.x, bar.width - half))
                        barMenu.toggle()
                    }
                }
            }

            // Drag a file over the bar → scratchpad auto-opens so you can drop
            // into it. Focus-grab is suppressed while dragging (the drag source
            // app keeps focus), then restored via a short timer after the drag
            // leaves the bar so normal click-to-dismiss still works.
            DropArea {
                anchors.fill: parent

                onEntered: {
                    scratchpad.grabFocus         = false
                    scratchpad.dismissOnFocusLoss = false
                    if (!scratchpad.shown) scratchpad.shown = true
                }

                // Give enough time for the pointer to reach the scratchpad popup.
                onExited:  dragRestoreTimer.restart()

                // File dropped directly on the bar (not on the popup) — forward it.
                onDropped: drop => {
                    dragRestoreTimer.stop()
                    if (drop.hasUrls) {
                        for (const u of drop.urls) scratchpad.addUrl(u.toString())
                        drop.accept(Qt.CopyAction)
                    }
                    dragRestoreTimer.triggered()
                }

                Timer {
                    id: dragRestoreTimer
                    interval: 2000
                    onTriggered: {
                        scratchpad.grabFocus          = true
                        scratchpad.dismissOnFocusLoss = true
                    }
                }
            }

            // invisible nub the scratchpad morphs out of — left-aligned with hot corner
            Item {
                id: scratchAnchor
                anchors { top: parent.top; left: parent.left }
                width: 20
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

                  // Media { Layout.fillHeight: true }

                  // ActiveWindow { Layout.fillHeight: true }
              }

              // CENTER
              RowLayout {
                  anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing

                  Clock { Layout.fillHeight: true }

              }

              // RIGHT
              RowLayout {
                  anchors { right: parent.right; rightMargin: 14; top: parent.top; bottom: parent.bottom }
                  spacing: Theme.moduleSpacing

                  Tray { Layout.fillHeight: true; Layout.alignment: Qt.AlignVCenter }

                  Caffeine { Layout.fillHeight: true }

                  NotificationBell { Layout.fillHeight: true }

                  WifiIndicator { Layout.fillHeight: true }

                  BluetoothIndicator { Layout.fillHeight: true }

                  Volume { Layout.fillHeight: true }

                  Battery { Layout.fillHeight: true }
              }
            }
        }
    }
}
