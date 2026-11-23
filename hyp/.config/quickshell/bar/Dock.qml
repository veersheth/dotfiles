import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.common

// A floating, bottom-only window dock. It never reserves layout space; while
// auto-hide is on, only a thin strip at the bottom edge is interactive until
// the pointer reveals it. The mask is deliberately independent of the card's
// slide transform so the reveal strip cannot lose hover mid-animation.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root
        required property var modelData
        screen: modelData

        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: root.dockHeight

        readonly property int iconSize: DockState.dockIconSize
        readonly property int padding: Theme.dockPadding
        readonly property int iconPadding: Theme.dockPadding
        readonly property int cardHeight: root.iconSize
            + root.iconPadding * 2
            + root.padding * 2
        readonly property int dockHeight: root.cardHeight
        readonly property int revealEdge: 3

        readonly property bool floating: DockState.dockAutoHide
        readonly property bool tuckedAway: root.floating && !DockState.dockPeek

        visible: !BarState.exposeActive || BarState.exposeGestureTracking
        exclusiveZone: -1
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:dock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight : 0

        // The input region matches the themed card exactly while revealed,
        // and the thin reveal line while tucked away. Icon touch slots use
        // padding instead of explicit gaps, so the whole card stays continuous.
        mask: Region {
            x: windowList.windowCount === 0 || root.tuckedAway ? 0 : dockCard.x
            y: windowList.windowCount === 0
                ? 0
                : root.tuckedAway
                    ? root.height - root.revealEdge
                    : dockCard.y
            width: windowList.windowCount === 0
                ? 0
                : root.tuckedAway
                    ? root.width
                    : dockCard.width
            height: windowList.windowCount === 0
                ? 0
                : root.tuckedAway
                    ? root.revealEdge
                    : dockCard.height
        }

        MouseArea {
            id: revealStrip
            property bool edgeHovered: false
            visible: root.floating
            enabled: root.floating
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 30
            height: root.revealEdge
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            onEntered: {
                edgeHovered = true
                DockHover.enter("edge")
                DockState.triggerEdgePeek()
            }
            onPositionChanged: if (containsMouse) DockState.triggerEdgePeek()
            onExited: {
                edgeHovered = false
                DockHover.leave("edge")
                DockState.rearmEdge()
            }
        }

        Timer {
            id: peekRetractTimer
            interval: 500
            onTriggered: {
                if (windowList.dragKey !== "" || revealStrip.edgeHovered || DockHover.active) {
                    peekRetractTimer.restart()
                    return
                }
                DockState.hideDockPeek()
            }
        }

        Connections {
            target: DockHover
            function onActiveChanged() {
                if (DockHover.active || windowList.dragKey !== "") peekRetractTimer.stop()
                else peekRetractTimer.restart()
            }
        }

        Connections {
            target: DockState
            function onDockPeekChanged() {
                if (DockState.dockPeek && !DockHover.active)
                    peekRetractTimer.restart()
            }
            function onDockAutoHideChanged() {
                if (!DockState.dockAutoHide) peekRetractTimer.stop()
            }
        }

        Connections {
            target: BarState
            function onExposeActiveChanged() {
                if (BarState.exposeActive && !BarState.exposeGestureTracking)
                    DockState.hideDockPeek()
            }
        }

        RectangularShadow {
            id: dockShadow
            x: dockCard.x
            y: dockCard.y
            width: dockCard.width
            height: dockCard.height
            radius: Theme.radius
            blur: 12
            offset.y: -1
            color: "#80000000"
            visible: dockCard.visible

            transform: Translate {
                y: root.tuckedAway ? root.dockHeight : 0
                Behavior on y {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            id: dockCard
            visible: windowList.windowCount > 0
            width: windowList.implicitWidth + root.padding * 2
            height: root.cardHeight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth

            transform: Translate {
                y: root.tuckedAway ? root.dockHeight : 0
                Behavior on y {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
            }

            // Keeps the dock revealed while the pointer rests on the card,
            // including the gaps between window icons.
            MouseArea {
                id: cardHover
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                z: 0
                onEntered: DockHover.enter("card")
                onExited: DockHover.leave("card")
            }

            // Ctrl+scroll on a mouse wheel or trackpad resizes the icons.
            WheelHandler {
                target: null
                acceptedButtons: Qt.NoButton
                acceptedModifiers: Qt.ControlModifier
                property real accum: 0
                onWheel: event => {
                    const angle = event.angleDelta.y;
                    const pixels = event.pixelDelta.y;
                    accum += Math.abs(angle) > 0 ? angle : -pixels;
                    const step = Math.abs(angle) > 0 ? 120 : 40;
                    while (Math.abs(accum) >= step) {
                        DockState.nudgeIconSize(accum > 0 ? 1 : -1);
                        accum -= accum > 0 ? step : -step;
                    }
                }
            }

            // Touch/trackpad pinch resizes by the same persisted value.
            PinchHandler {
                target: null
                onScaleChanged: delta => DockState.scaleIconSize(delta)
            }

            Taskbar {
                id: windowList
                anchors.centerIn: parent
                z: 1
                slotSize: root.iconSize
                iconSize: root.iconSize
                iconPadding: root.iconPadding
                hoverRadius: Theme.itemRadius
                itemSpacing: 0
                monitorName: root.screen?.name ?? ""
                hoverTracker: DockHover
                hoverOwner: "icons"
                trackHover: true
                pinnedMode: true
                showTooltips: true
                tooltipEdgeMargin: (BarState.barBottom ? Theme.barHeight : 0) + root.dockHeight + 4
                monochromeInactive: false
                inactiveOpacity: 1.0
            }

            // One dot centered under the active icon; it slides when focus moves.
            Rectangle {
                id: activeDot
                width: 4
                height: 4
                radius: 2
                x: windowList.activeIndex < 0
                    ? -width
                    : root.padding
                        + windowList.activeIndex
                            * (root.iconSize + root.iconPadding * 2 + windowList.itemSpacing)
                        + root.iconPadding
                        + (root.iconSize - width) / 2
                y: parent.height - height - root.padding / 2
                color: Theme.blue
                visible: windowList.activeIndex >= 0 && !root.tuckedAway

                Behavior on x {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }

        Connections {
            target: windowList
            function onDragKeyChanged() {
                if (windowList.dragKey !== "") {
                    DockState.showDockPeek()
                    peekRetractTimer.stop()
                } else {
                    peekRetractTimer.restart()
                }
            }
            function onWindowCountChanged() {
                if (windowList.windowCount === 0) DockState.hideDockPeek()
                else peekRetractTimer.restart()
            }
        }
    }
}
