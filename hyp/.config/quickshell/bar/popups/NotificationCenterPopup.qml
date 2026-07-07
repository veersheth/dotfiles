import Quickshell
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

    contentWidth:  340
    contentHeight: header.implicitHeight
                 + (notifs.length > 0 ? Math.min(380, list.contentHeight + 12) : 72)

    ColumnLayout {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   16
            Layout.leftMargin:  18
            Layout.rightMargin: 18

            Text {
                text: "Notifications"
                font.family:    Theme.font
                font.pixelSize: Theme.fontSize + 2
                font.weight:    Font.DemiBold
                color: Theme.foreground
            }
            Item { Layout.fillWidth: true }

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

        // Do not disturb row
        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   12
            Layout.leftMargin:  18
            Layout.rightMargin: 18
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
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 14
            implicitHeight:   Theme.borderWidth
            color: Theme.border
        }
    }

    // Empty state
    Text {
        anchors { top: header.bottom; topMargin: 26; horizontalCenter: parent.horizontalCenter }
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
        spacing: 6
        model: root.notifs
        leftMargin: 12; rightMargin: 12; topMargin: 2; bottomMargin: 8
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData

            width: list.width - 24
            height: row.implicitHeight + 20
            radius: 12
            color: itemMouse.containsMouse ? Theme.hoverStrong : Theme.surface
            border.width: Theme.borderWidth
            border.color: Theme.border

            RowLayout {
                id: row
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 10

                IconImage {
                    readonly property string src: modelData.image !== ""
                        ? modelData.image
                        : Quickshell.iconPath(modelData.appIcon, true)
                    visible: src !== ""
                    source:  src
                    Layout.alignment: Qt.AlignTop
                    implicitSize: 26
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        elide:   Text.ElideRight
                        text:    modelData.appName
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        color: Qt.alpha(Theme.foreground, 0.5)
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text:  modelData.summary
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight:    Font.DemiBold
                        color: Theme.foreground
                    }
                    Text {
                        Layout.fillWidth: true
                        visible:          text !== ""
                        wrapMode:         Text.Wrap
                        maximumLineCount: 2
                        elide:            Text.ElideRight
                        textFormat:       Text.StyledText
                        text:             modelData.body
                        font.family:      Theme.font
                        font.pixelSize:   Theme.fontSize - 1
                        color: Qt.alpha(Theme.foreground, 0.7)
                    }
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: parent.modelData.dismiss()
            }
        }
    }
}
