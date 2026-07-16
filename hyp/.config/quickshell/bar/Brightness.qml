import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    implicitWidth:  icon.implicitWidth + 16
    implicitHeight: Theme.pillHeight
    visible: brightPopup.hasDisplay

    Text {
        id: icon
        anchors.centerIn: parent
        text: {
            const b = brightPopup.brightness
            return b < 0.34 ? "󰃞" : b < 0.67 ? "󰃟" : "󰃠"
        }
        font.family:    Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: Theme.foreground
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
        onClicked: brightPopup.toggle()
    }

    BrightnessPopup {
        id: brightPopup
        anchorItem: root
    }
}
