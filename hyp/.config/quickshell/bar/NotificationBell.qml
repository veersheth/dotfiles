import QtQuick
import qs.common
import qs.components
import qs.notifications
import qs.bar.popups

// Bell icon: opens the notification centre, shows unread + dnd state.
// Fixed-width wrapper so glyph-width differences between icons never shift the bar layout.
Item {
    id: root
    readonly property int count: NotificationService.unreadCount

    // Use the wider glyph's width as the constant size
    implicitWidth: sizer.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    Text {
        id: sizer
        visible: false
        text: "󰂞"
        font.family:    Theme.nerdFont
        font.pixelSize: Theme.iconSize
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: NotificationService.dnd ? "󰂛"
            : root.count > 0          ? "󰂞"
            :                           "󰂜"
        font.family:    Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: NotificationService.dnd ? Theme.blue
             : root.count > 0          ? Theme.foreground
             :                           Qt.alpha(Theme.foreground, 0.45)
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: hitArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onEntered: tip.show(root)
        onExited:  tip.hide()
        onClicked: {
            tip.hide()
            NotificationService.dismiss()
            if (!centerLoader.active) {
                centerLoader.active = true
            } else {
                centerLoader.item.toggle()
            }
        }
    }

    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14
        Text {
            id: tipText
            anchors.centerIn: parent
            text: NotificationService.dnd
                ? "Do not disturb"
                : root.count > 0
                    ? `${root.count} notification${root.count === 1 ? "" : "s"}`
                    : "No notifications"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    Loader {
        id: centerLoader
        active: false
        sourceComponent: Component {
            NotificationCenterPopup {}
        }
        onLoaded: {
            item.anchorItem = root
            item.toggle()
        }
    }
}
