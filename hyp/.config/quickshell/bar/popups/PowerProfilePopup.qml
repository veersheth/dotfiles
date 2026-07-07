import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Power profile picker backed by power-profiles-daemon via UPower.
BarPopup {
    id: root

    contentWidth: col.implicitWidth + 20
    contentHeight: col.implicitHeight + 20

    component ProfileRow: Rectangle {
        id: profileRow
        required property int profile
        required property string icon
        required property string label
        readonly property bool active: PowerProfiles.profile === profile

        Layout.fillWidth: true
        implicitWidth: 180
        implicitHeight: 36
        radius: 10
        color: active ? Qt.alpha(Theme.blue, 0.25)
             : rowMouse.containsMouse ? Theme.hover
             : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animDuration } }

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 10

            Text {
                text: profileRow.icon
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize
                color: profileRow.active ? Theme.blue : Theme.foreground
            }

            Text {
                Layout.fillWidth: true
                text: profileRow.label
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }

            Text {
                visible: profileRow.active
                text: "󰄬"
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize - 2
                color: Theme.blue
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                PowerProfiles.profile = profileRow.profile;
                root.close();
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.leftMargin: 12
            Layout.bottomMargin: 2
            text: "Power Profile"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        ProfileRow { profile: PowerProfile.PowerSaver;   icon: "󰌪"; label: "Power Saver" }
        ProfileRow { profile: PowerProfile.Balanced;     icon: "󰾅"; label: "Balanced" }
        ProfileRow {
            profile: PowerProfile.Performance
            icon: "󰓅"
            label: "Performance"
            visible: PowerProfiles.hasPerformanceProfile
        }
    }
}
