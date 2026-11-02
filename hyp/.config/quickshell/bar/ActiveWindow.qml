import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

Item {
    id: root
    readonly property var active: ToplevelManager.activeToplevel
    property color foreground: Theme.foreground
    property real maximumWidth: 320
    readonly property string appId: active?.appId ?? ""
    readonly property string appName: {
        if (!appId) return ""
        const entry = DesktopEntries.heuristicLookup(appId)
        if (entry?.name) return entry.name
        const raw = appId.split(".").pop()
        return raw.charAt(0).toUpperCase() + raw.slice(1)
    }

    visible: appName !== "" && maximumWidth > 0
    implicitWidth: Math.min(nameText.implicitWidth, maximumWidth)
    implicitHeight: Theme.pillHeight

    Text {
        id: nameText
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        text: root.appName
        textFormat: Text.PlainText
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Normal
        color: Qt.alpha(root.foreground, 0.4)
    }
}
