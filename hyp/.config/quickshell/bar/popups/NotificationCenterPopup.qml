import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.common
import qs.components
import qs.notifications

// Full-height notification drawer that slides in from the right edge.
// Use toggle() / close() from the bar; anchorItem is used only for screen lookup.
PanelWindow {
    id: root

    property Item anchorItem: null
    property bool shown: false
    property double dismissedAt: 0
    property bool dismissing: false
    readonly property int shadowPadding: 16
    Component.onDestruction: BarState.releasePopup(root)

    readonly property var notifs: [...NotificationService.notifications.values].reverse()

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }
    function closeForReplacement() {
        shown = false
        exitAnim.stop()
        visible = false
    }

    function dismissCard(card) {
        if (dismissing) return
        dismissing = true
        const distance = card.height + list.spacing
        for (let i = card.index + 1; i < list.count; ++i) {
            const below = list.itemAtIndex(i)
            if (below) below.slideOffset = -distance
        }
        card.fadeDismiss()
    }

    screen: anchorItem?.QsWindow.window?.screen ?? null
    anchors.top:    true
    anchors.bottom: true
    anchors.right:  true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    onShownChanged: {
        if (shown) {
            BarState.activatePopup(root)
            exitAnim.stop()
            if (!visible) panel.x = panel.width + root.shadowPadding * 2
            visible = true
            enterAnim.restart()
            Qt.callLater(() => {
                if (root.shown) panel.forceActiveFocus()
            })
        } else {
            BarState.releasePopup(root)
            enterAnim.stop()
            exitAnim.restart()
        }
    }

    BarClickAway {
        screen: root.screen
        visible: root.shown && !Compositor.hyprland
        popupX: width - root.width + root.shadowPadding
        popupY: BarState.barBottom ? 8 : Theme.barHeight + 8
        popupWidth: panel.width
        popupHeight: root.height
        onDismissed: {
            root.dismissedAt = Date.now()
            root.close()
        }
    }

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.margins.top:    BarState.barBottom ? 8 : Theme.barHeight + 8
    WlrLayershell.margins.bottom: BarState.barBottom ? Theme.barHeight + 8 : 8
    WlrLayershell.margins.right:  0

    implicitWidth: 380 + shadowPadding * 2
    mask: Region { x: root.shadowPadding; y: panel.y; width: panel.width; height: panel.height }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.close()
    }

    NumberAnimation {
        id: enterAnim
        target: panel; property: "x"
        to: root.shadowPadding; duration: 240; easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: exitAnim
        target: panel; property: "x"
        to: panel.width + root.shadowPadding * 2
        duration: 180; easing.type: Easing.InCubic
        onFinished: if (!root.shown) root.visible = false
    }

    RectangularShadow {
        x: panel.x
        y: panel.y
        width: panel.width
        height: panel.height
        radius: Theme.popupRadius
        blur: 14
        offset.x: -3
        color: "#80000000"
    }

    Loader {
        active: Compositor.hyprland
        sourceComponent: HyprlandFocusGrab {
            windows: [root]
            active: root.shown
            onCleared: {
                if (!root.shown) return
                root.dismissedAt = Date.now()
                root.shown = false
            }
        }
    }

    Rectangle {
        id: panel
        focus: true
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width: 380
        x: root.shadowPadding
        radius: Theme.popupRadius
        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Header ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth:   true
                Layout.topMargin:   16
                Layout.leftMargin:  22
                Layout.rightMargin: 22
                Layout.bottomMargin: 12
                spacing: 10

                Text {
                    text: NotificationService.dnd ? "󰂛" : "󰂚"
                    font.family: Theme.nerdFont
                    font.pixelSize: 15
                    color: NotificationService.dnd ? Theme.blue : Qt.alpha(Theme.foreground, 0.6)
                }
                Text {
                    text: "Do not disturb"
                    font.family:    Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.foreground
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 38; implicitHeight: 20; radius: height / 2
                    color: NotificationService.dnd ? Theme.blue : Theme.hover
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 14; height: 14; radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: NotificationService.dnd ? parent.width - width - 3 : 3
                        color: NotificationService.dnd ? Theme.onAccent : Theme.foreground
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationService.dnd = !NotificationService.dnd
                    }
                }

                Rectangle {
                    implicitWidth: 28; implicitHeight: 28; radius: width / 2
                    color: clearMouse.containsMouse ? Theme.hover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰎟"
                        font.family: Theme.nerdFont
                        font.pixelSize: 15
                        color: Qt.alpha(Theme.foreground, 0.7)
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            list.positionViewAtBeginning()
                            NotificationService.clearAll()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.borderWidth
                color: Theme.border
            }

            // ── Empty state ───────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.notifs.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    font.family:    Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Qt.alpha(Theme.foreground, 0.4)
                }
            }

            // ── Notification list ─────────────────────────────────────
            ListView {
                id: list
                Layout.fillWidth:  true
                Layout.fillHeight: true
                visible: root.notifs.length > 0
                clip: true
                spacing: 8
                model: root.notifs
                leftMargin: 14; rightMargin: 14
                topMargin: 10; bottomMargin: 14
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: notifCard
                    required property var modelData
                    required property int index
                    property real slideOffset: 0
                    function fadeDismiss() { fadeOut.start() }
                    Behavior on slideOffset {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                    transform: Translate { y: notifCard.slideOffset }

                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                    width: list.width - 28
                    height: row.implicitHeight + 36
                    radius: Theme.popupRadius
                    color: Theme.background
                    border.width: Theme.borderWidth
                    border.color: critical ? Qt.alpha(Theme.red, 0.6) : Theme.border

                    NumberAnimation {
                        id: fadeOut
                        target: notifCard
                        property: "opacity"
                        to: 0
                        duration: 180
                        onFinished: {
                            root.dismissing = false
                            notifCard.modelData.dismiss()
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: false
                        onClicked: root.dismissCard(notifCard)
                    }

                    RowLayout {
                        id: row
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 12

                        IconImage {
                            readonly property string src: modelData.image !== ""
                                ? modelData.image
                                : Quickshell.iconPath(modelData.appIcon, true)
                            visible: src !== ""
                            source:  src
                            Layout.alignment: Qt.AlignTop
                            implicitSize: 36
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                elide:   Text.ElideRight
                                text:    modelData.appName
                                font.family:    Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                color: Qt.alpha(Theme.foreground, 0.5)
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text:  modelData.summary
                                font.family:    Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.weight:    Font.DemiBold
                                color: Theme.foreground
                            }
                            Text {
                                Layout.fillWidth: true
                                visible:          text !== ""
                                wrapMode:         Text.Wrap
                                maximumLineCount: 3
                                elide:            Text.ElideRight
                                textFormat:       Text.StyledText
                                text:             modelData.body
                                font.family:      Theme.font
                                font.pixelSize:   Theme.fontSize
                                color: Qt.alpha(Theme.foreground, 0.75)
                            }

                            RowLayout {
                                visible: modelData.actions.length > 0
                                Layout.topMargin: 4
                                spacing: 6

                                Repeater {
                                    model: modelData.actions
                                    Rectangle {
                                        required property var modelData
                                        implicitWidth:  actionText.implicitWidth + 20
                                        implicitHeight: 26
                                        radius: Theme.smallRadius
                                        color: actionMouse.containsMouse ? Theme.hoverStrong : Theme.hover

                                        Text {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text:           parent.modelData.text
                                            font.family:    Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                            font.weight:    Font.Medium
                                            color:          Theme.foreground
                                        }
                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked:    parent.modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
