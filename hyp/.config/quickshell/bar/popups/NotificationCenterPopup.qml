import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
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

    readonly property var notifs: [...NotificationService.notifications.values].reverse()

    function toggle() {
        if (shown) { shown = false; return; }
        if (Date.now() - dismissedAt < 150) return;
        shown = true;
    }
    function close() { shown = false; }

    screen: anchorItem?.Window.window?.screen ?? null
    anchors.top:    true
    anchors.bottom: true
    anchors.right:  true
    exclusiveZone: -1
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.margins.top:    Theme.barHeight + 8
    WlrLayershell.margins.bottom: 8
    WlrLayershell.margins.right:  8

    implicitWidth: 380

    onShownChanged: {
        if (shown) {
            exitAnim.stop()
            panel.x = panel.width
            visible = true
            enterAnim.restart()
        } else {
            enterAnim.stop()
            exitAnim.restart()
        }
    }

    NumberAnimation {
        id: enterAnim
        target: panel; property: "x"
        to: 0; duration: 260; easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: panel; property: "x"
            to: panel.width; duration: 220; easing.type: Easing.InCubic
        }
        ScriptAction { script: root.visible = false }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: {
            root.dismissedAt = Date.now()
            root.shown = false
        }
    }

    Rectangle {
        id: panel
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        x: parent.width
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
                    visible: root.notifs.length > 0
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
                        onClicked: NotificationService.clearAll()
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
                    required property var modelData

                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                    width: list.width - 28
                    height: row.implicitHeight + 36
                    radius: Theme.popupRadius
                    color: itemMouse.containsMouse ? Theme.hoverStrong : Theme.background
                    border.width: Theme.borderWidth
                    border.color: critical ? Qt.alpha(Theme.red, 0.6) : Theme.border

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: parent.modelData.dismiss()
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
