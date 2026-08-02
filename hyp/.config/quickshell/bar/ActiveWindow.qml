import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root
    readonly property var active: ToplevelManager.activeToplevel
    readonly property string appClass: active?.appId ?? ""
    readonly property string displayName: {
        if (appClass.length === 0) return ""
        const parts = appClass.split(".")
        const raw = parts.length > 1 ? parts[parts.length - 1] : appClass
        return raw.charAt(0).toUpperCase() + raw.slice(1)
    }

    visible: appClass !== ""
    implicitWidth: iconText.implicitWidth + 6 + Math.min(nameText.implicitWidth, 240) + 20
    implicitHeight: Theme.pillHeight

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: awMouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
        id: nameText
        anchors { left: iconText.right; verticalCenter: parent.verticalCenter }
        width: Math.min(implicitWidth, 240)
        elide: Text.ElideRight
        text: displayName
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        color: Qt.alpha(Theme.foreground, 0.4)
    }

    MouseArea {
        id: awMouse
        anchors.fill: parent
        hoverEnabled: true
    }
}
