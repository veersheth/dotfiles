import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.notifications

// Notification centre — history list with a do-not-disturb toggle.
// Leaks from the bell in the upper-right corner of the bar.
BarPopup {
    id: root

    readonly property var notifs: [...NotificationService.notifications.values].reverse()

    contentWidth:  360
    contentHeight: header.implicitHeight
                 + (notifs.length > 0 ? Math.min(400, list.contentHeight + 20) : 84)

    ColumnLayout {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        // Do not disturb row
        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   16
            Layout.leftMargin:  22
            Layout.rightMargin: 22
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

            // Toggle switch
            Rectangle {
                implicitWidth: 38; implicitHeight: 20; radius: 10
                color: NotificationService.dnd ? Theme.blue : Theme.hover
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 14; height: 14; radius: 7
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

            // Clear all
            Rectangle {
                implicitWidth: 28; implicitHeight: 28; radius: 14
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
            Layout.topMargin: 18
            implicitHeight:   Theme.borderWidth
            color: Theme.border
        }
    }

    // Empty state
    Text {
        anchors { top: header.bottom; topMargin: 32; horizontalCenter: parent.horizontalCenter }
        visible: root.notifs.length === 0
        text: "No notifications"
        font.family:    Theme.font
        font.pixelSize: Theme.fontSize
        color: Qt.alpha(Theme.foreground, 0.4)
    }

    ListView {
        id: list
        anchors {
            top: header.bottom; topMargin: 6
            left: parent.left; right: parent.right; bottom: parent.bottom
        }
        visible: root.notifs.length > 0
        clip: true
        spacing: 10
        model: root.notifs
        leftMargin: 16; rightMargin: 16; topMargin: 4; bottomMargin: 14
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData

            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

            width: list.width - 32
            height: row.implicitHeight + 36
            radius: Theme.popupRadius
            color: itemMouse.containsMouse ? Theme.surface : Theme.background
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
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
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
                                radius: 6
                                color: actionMouse.containsMouse ? Theme.hoverStrong : Theme.hover

                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text:            parent.modelData.text
                                    font.family:     Theme.font
                                    font.pixelSize:  Theme.fontSize - 1
                                    font.weight:     Font.Medium
                                    color:           Theme.foreground
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
