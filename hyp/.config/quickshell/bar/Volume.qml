import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root

    readonly property var  sink:   Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false

    Layout.alignment: Qt.AlignVCenter
    implicitWidth:  volIcon.implicitWidth + 16
    implicitHeight: Theme.pillHeight
    visible: sink !== null

    Text {
        id: volIcon
        anchors.centerIn: parent
        text: root.muted          ? "󰝟"
            : root.volume < 0.33  ? "󰕿"
            : root.volume < 0.66  ? "󰖀"
            : "󰕾"
        font.family:    Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: root.muted ? Qt.alpha(Theme.foreground, 0.45) : Theme.foreground
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
            if (!volLoader.active) {
                volLoader.active = true
            } else {
                volLoader.item.toggle()
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
            text: root.muted
                ? `Muted · ${Math.round(root.volume * 100)}%`
                : `${Math.round(root.volume * 100)}%`
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: root.muted ? Qt.alpha(Theme.foreground, 0.55) : Theme.foreground
        }
    }

    Loader {
        id: volLoader
        active: false
        sourceComponent: Component {
            VolumePopup {}
        }
        onLoaded: {
            item.anchorItem = root
            item.toggle()
        }
    }
}
