import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common

RowLayout {
    readonly property var active: ToplevelManager.activeToplevel
    readonly property string appClass: active?.appId ?? ""
    readonly property string displayName: {
        if (appClass.length === 0) return ""
        const parts = appClass.split(".")
        const raw = parts.length > 1 ? parts[parts.length - 1] : appClass
        return raw.charAt(0).toUpperCase() + raw.slice(1)
    }

    visible: appClass !== ""
    spacing: 6
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 10

    Text {
        text: ""
        font.family: Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: Qt.alpha(Theme.foreground, 0.3)
    }

    Text {
        Layout.maximumWidth: 260
        elide: Text.ElideRight
        text: displayName
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        color: Qt.alpha(Theme.foreground, 0.4)
    }
}
