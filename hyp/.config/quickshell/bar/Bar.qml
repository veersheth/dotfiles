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
        visible: !BarState.exposeActive || BarState.exposeGestureTracking

        anchors.top:    !BarState.barBottom
        anchors.bottom: BarState.barBottom
        anchors.left:   true
        anchors.right:  true
        implicitHeight: Theme.barHeight
        readonly property int revealEdge: 3
        readonly property bool floating: BarState.barAutoHide
        readonly property bool tuckedAway: floating && !BarState.barPeek
        exclusiveZone: root.floating ? -1
            : (BarState.exposeActive && !BarState.exposeGestureTracking ? 0 : Theme.barHeight)
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:bar"

        // Auto-hide uses -1 so the floating bar never enters the compositor's
        // exclusive-zone layout; only the thin edge strip is interactive while
        // tucked away.
        mask: Region {
            x: 0
            y: root.tuckedAway ? (BarState.barBottom ? root.height - root.revealEdge : 0) : 0
            width: root.width
            height: root.tuckedAway ? root.revealEdge : Theme.barHeight
        }

        MouseArea {
            id: revealStrip
            property bool edgeHovered: false
            visible: root.floating
            enabled: root.floating
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 20
            height: root.revealEdge
            anchors {
                left: parent.left
                right: parent.right
                top: BarState.barBottom ? undefined : parent.top
                bottom: BarState.barBottom ? parent.bottom : undefined
            }
            onEntered: {
                edgeHovered = true
                BarHover.enter()
                BarState.triggerEdgePeek()
            }
            onPositionChanged: if (containsMouse) BarState.triggerEdgePeek()
            onExited: {
                edgeHovered = false
                BarHover.leave()
                BarState.rearmEdge()
            }
        }

        Timer {
            id: peekRetractTimer
            interval: 350
            onTriggered: {
                if (revealStrip.edgeHovered) {
                    peekRetractTimer.restart()
                    return
                }
                if (!BarHover.active && !BarState.activePopup && !BarState.rearrangeModules)
                    BarState.hideBarPeek()
            }
        }

        Connections {
            target: BarHover
            function onActiveChanged() {
                if (BarHover.active) peekRetractTimer.stop()
                else peekRetractTimer.restart()
            }
        }

        Connections {
            target: BarState
            function onActivePopupChanged() {
                if (BarState.activePopup) peekRetractTimer.stop()
                else peekRetractTimer.restart()
            }
            function onBarPeekChanged() {
                if (BarState.barPeek && !BarHover.active && !BarState.activePopup)
                    peekRetractTimer.restart()
            }
            function onRearrangeModulesChanged() {
                if (BarState.rearrangeModules) peekRetractTimer.stop()
                else peekRetractTimer.restart()
            }
        }

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
            transform: Translate {
                y: (BarState.exposeGestureTracking
                        ? (BarState.barBottom ? 1 : -1) * bar.height
                            * BarState.exposeGestureProgress
                        : 0)
                    + (root.tuckedAway
                        ? (BarState.barBottom ? bar.height : -bar.height)
                        : 0)
                Behavior on y {
                    enabled: !BarState.exposeGestureTracking
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
            color: BarState.transparent && !BarState.barAutoHide ? "transparent" : Theme.background

            // Empty bar space → context menu (right-click).
            // First child, so every module's own MouseArea stays on top.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                onEntered: BarHover.enter()
                onExited: BarHover.leave()
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const half = barMenu.contentWidth / 2 + 8
                        barMenuAnchor.x = Math.max(half, Math.min(mouse.x, bar.width - half))
                        barMenu.toggle()
                    }
                }
                onDoubleClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) BarState.toggleBarAutoHide()
                }
            }

            // moves to click x before the menu opens
            Item {
                id: barMenuAnchor
                anchors.top: parent.top
                width: 1; height: parent.height
            }

            ShellContextMenu {
                id: barMenu
                anchorItem: barMenuAnchor
            }

            Rectangle {
                anchors.top:    BarState.barBottom ? parent.top    : undefined
                anchors.bottom: BarState.barBottom ? undefined      : parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: Theme.borderWidth
                color: BarState.transparent && !BarState.barAutoHide ? "transparent" : Theme.barBorder
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
                  rearrangeMode: BarState.rearrangeModules
              }
            }

        }
    }
}
