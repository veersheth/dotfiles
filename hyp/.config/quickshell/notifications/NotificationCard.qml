import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common

// Single notification card — slides in from the right, auto-expires.
Rectangle {
    id: card

    required property var notif

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    property bool exiting: false

    width:  parent ? parent.width : 340
    height: layout.implicitHeight + 36
    radius: Theme.popupRadius
    color:  Theme.surface
    border.width: Theme.borderWidth
    border.color: critical ? Qt.alpha(Theme.red, 0.6) : Theme.border

    x: width + 16
    opacity: 0
    Component.onCompleted: enterAnim.start()

    RetainableLock { object: card.notif; locked: true }

    Connections {
        target: card.notif
        function onClosed() { card.exit(); }
    }

    // Timeout hides the popup but keeps the notification tracked so it
    // remains in the notification centre; only explicit dismissal drops it.
    Timer {
        interval: card.notif.expireTimeout >= 1000 ? card.notif.expireTimeout : 5000
        running:  !card.critical && !card.exiting
        onTriggered: card.exit()
    }

    function exit() {
        if (exiting) return;
        exiting = true;
        enterAnim.stop();
        exitAnim.start();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: card; property: "x";       to: 0;  duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "opacity"; to: 1;  duration: 220; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation { target: card; property: "x";       to: card.width + 16; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: card; property: "opacity"; to: 0;               duration: 200; easing.type: Easing.InCubic }
        }
        ScriptAction { script: card.destroy() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: card.notif.dismiss()
    }

    RowLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 12

        IconImage {
            readonly property string src: card.notif.image !== ""
                ? card.notif.image
                : Quickshell.iconPath(card.notif.appIcon, true)
            visible:  src !== ""
            source:   src
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
                text:    card.notif.appName
                font.family:    Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Qt.alpha(Theme.foreground, 0.5)
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text:  card.notif.summary
                font.family:    Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight:    Font.DemiBold
                color: Theme.foreground
            }
            Text {
                Layout.fillWidth: true
                visible:         text !== ""
                wrapMode:        Text.Wrap
                maximumLineCount: 3
                elide:           Text.ElideRight
                textFormat:      Text.StyledText
                text:            card.notif.body
                font.family:     Theme.font
                font.pixelSize:  Theme.fontSize
                color: Qt.alpha(Theme.foreground, 0.75)
            }

            RowLayout {
                visible: card.notif.actions.length > 0
                Layout.topMargin: 4
                spacing: 6

                Repeater {
                    model: card.notif.actions
                    Rectangle {
                        required property var modelData
                        implicitWidth:  actionText.implicitWidth + 20
                        implicitHeight: 26
                        radius: Theme.smallRadius
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
