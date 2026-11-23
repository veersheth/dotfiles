import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.common

// The right-hand bar modules can be dragged into a saved order.
Item {
    id: root
    property color foreground: Theme.foreground
    property bool locked: false
    property bool rearrangeMode: false
    property string draggingKey: ""
    property real dragX: 0
    property real markerX: 0
    property int dropIndex: 0

    implicitWidth: modulesRow.implicitWidth
    implicitHeight: Theme.barHeight

    function labelFor(key) {
        switch (key) {
        case "tray": return "Tray"
        case "caffeine": return "Caffeine"
        case "wifi": return "Wi-Fi"
        case "bluetooth": return "Bluetooth"
        case "clock": return "Clock"
        case "volume": return "Volume"
        case "battery": return "Battery"
        case "notifications": return "Notifications"
        case "power": return "Power"
        default: return key
        }
    }

    function beginDrag(slot, handler) {
        draggingKey = slot.modelData
        updateDrag(slot, handler)
    }

    function updateDrag(slot, handler) {
        if (!draggingKey) return
        const global = slot.mapToGlobal(handler.centroid.position.x,
            handler.centroid.position.y)
        const local = root.mapFromGlobal(global.x, global.y)
        dragX = Math.max(0, Math.min(root.width, local.x))
        for (let i = 0; i < moduleRepeater.count; ++i) {
            const candidate = moduleRepeater.itemAt(i)
            if (!candidate || !candidate.visible || candidate.modelData === draggingKey)
                continue
            if (dragX < modulesRow.x + candidate.x + candidate.width / 2) {
                dropIndex = i
                markerX = modulesRow.x + candidate.x
                return
            }
        }
        dropIndex = moduleRepeater.count
        markerX = modulesRow.x + modulesRow.width
    }

    function finishDrag() {
        if (!draggingKey) return
        BarModuleOrder.move(draggingKey, dropIndex)
        draggingKey = ""
    }

    Component { id: trayComponent; Tray { foreground: root.foreground } }
    Component { id: caffeineComponent; Caffeine { foreground: root.foreground } }
    Component { id: caffeineDisplayComponent; CaffeineDisplay { foreground: root.foreground } }
    Component { id: wifiComponent; WifiIndicator { foreground: root.foreground } }
    Component { id: bluetoothComponent; BluetoothIndicator { foreground: root.foreground } }
    Component { id: clockComponent; Clock { foreground: root.foreground } }
    Component { id: volumeComponent; Volume { foreground: root.foreground } }
    Component { id: batteryComponent; Battery { foreground: root.foreground } }
    Component { id: notificationComponent; NotificationBell { foreground: root.foreground } }
    Component { id: powerComponent; Power { foreground: root.foreground } }

    RowLayout {
        id: modulesRow
        anchors.fill: parent
        spacing: Theme.moduleSpacing

        Repeater {
            id: moduleRepeater
            model: BarModuleOrder.modules
            Item {
                id: slot
                required property string modelData
                visible: modelData !== "tray"
                    || (!root.locked && SystemTray.items.values.length > 0)
                Layout.fillHeight: true
                implicitWidth: moduleLoader.implicitWidth
                implicitHeight: Theme.pillHeight
                opacity: root.draggingKey === modelData ? 0.35 : 1

                Loader {
                    id: moduleLoader
                    anchors.fill: parent
                    sourceComponent: {
                        switch (slot.modelData) {
                        case "tray": return root.locked ? null : trayComponent
                        case "caffeine": return root.locked
                            ? caffeineDisplayComponent : caffeineComponent
                        case "wifi": return wifiComponent
                        case "bluetooth": return bluetoothComponent
                        case "clock": return clockComponent
                        case "volume": return volumeComponent
                        case "battery": return batteryComponent
                        case "notifications": return notificationComponent
                        case "power": return powerComponent
                        default: return null
                        }
                    }
                }

                Rectangle {
                    visible: root.rearrangeMode && !root.locked && slot.visible
                    anchors { fill: parent; margins: -2 }
                    radius: Theme.smallRadius
                    color: "transparent"
                    border.color: Theme.blue
                    border.width: 1
                    opacity: 0.55
                    z: 1
                }

                DragHandler {
                    id: dragHandler
                    target: null
                    acceptedButtons: Qt.LeftButton
                    acceptedModifiers: root.rearrangeMode ? Qt.NoModifier : Qt.ControlModifier
                    enabled: !root.locked
                    onActiveChanged: {
                        if (active) root.beginDrag(slot, dragHandler)
                        else root.finishDrag()
                    }
                    onActiveTranslationChanged: if (active) root.updateDrag(slot, dragHandler)
                }
            }
        }
    }

    Rectangle {
        visible: root.draggingKey !== ""
        x: root.markerX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Theme.pillHeight
        radius: width / 2
        color: Theme.blue
        z: 2
    }

    Rectangle {
        visible: root.draggingKey !== ""
        x: Math.max(0, Math.min(root.width - width, root.dragX - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: ghostLabel.implicitWidth + 20
        height: Theme.pillHeight
        radius: height / 2
        color: Theme.surface
        border.color: Theme.blue
        border.width: Theme.borderWidth
        z: 3
        Text {
            id: ghostLabel
            anchors.centerIn: parent
            text: root.labelFor(root.draggingKey)
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.foreground
        }
    }
}
