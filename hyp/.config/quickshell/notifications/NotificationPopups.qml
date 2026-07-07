import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.notifications

// Stack of slide-in notification cards at the top-right.
Scope {
    id: root

    Connections {
        target: NotificationService
        function onPopupNotification(notif) {
            cardComponent.createObject(stack, { notif });
        }
    }

    Component { id: cardComponent; NotificationCard {} }

    PanelWindow {
        anchors { top: true; right: true }
        margins { top: 8; right: 0 }
        exclusiveZone: 0
        implicitWidth:  356
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        visible: stack.children.length > 0
        mask: Region { item: stack }

        WlrLayershell.namespace: "quickshell:notifications"
        WlrLayershell.layer: WlrLayer.Top

        Column {
            id: stack
            anchors { top: parent.top; left: parent.left; right: parent.right; rightMargin: 12 }
            spacing: 8
            move: Transition {
                NumberAnimation { properties: "y"; duration: Theme.animDuration; easing.type: Easing.OutCubic }
            }
        }
    }
}
