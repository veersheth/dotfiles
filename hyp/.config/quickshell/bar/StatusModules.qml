import QtQuick
import QtQuick.Layouts
import qs.common

// Shared right-hand bar modules for the desktop and the session lock.
RowLayout {
    id: root
    property color foreground: Theme.foreground
    property bool locked: false
    enabled: !locked
    spacing: Theme.moduleSpacing

    // These controls own process state or expose running applications. Keep
    // their original instances on the desktop bar only.
    Loader {
        active: !root.locked
        visible: !root.locked
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignVCenter
        sourceComponent: Tray { foreground: root.foreground }
    }
    Loader {
        active: !root.locked
        visible: !root.locked
        Layout.fillHeight: true
        sourceComponent: Caffeine { foreground: root.foreground }
    }
    Loader {
        active: root.locked
        visible: root.locked
        Layout.fillHeight: true
        sourceComponent: CaffeineDisplay { foreground: root.foreground }
    }

    WifiIndicator { foreground: root.foreground; Layout.fillHeight: true }
    BluetoothIndicator { foreground: root.foreground; Layout.fillHeight: true }
    Clock { foreground: root.foreground; Layout.fillHeight: true }
    Volume { foreground: root.foreground; Layout.fillHeight: true }
    Battery { foreground: root.foreground; Layout.fillHeight: true }
    NotificationBell { foreground: root.foreground; Layout.fillHeight: true }
    Power { foreground: root.foreground; Layout.fillHeight: true }
}
