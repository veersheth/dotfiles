pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    signal popupNotification(var notif)

    property int  unreadCount: 0
    property bool dnd: false

    // Tracked notification history (newest last) for the notification centre
    readonly property var notifications: server.trackedNotifications

    function dismiss() { unreadCount = 0; }

    function clearAll() {
        const list = [...server.trackedNotifications.values];
        for (const n of list) n.dismiss();
        unreadCount = 0;
    }

    NotificationServer {
        id: server
        keepOnReload: true

        onNotification: notif => {
            root.unreadCount += 1;
            notif.tracked = true;
            if (!root.dnd) root.popupNotification(notif);
        }
    }
}
