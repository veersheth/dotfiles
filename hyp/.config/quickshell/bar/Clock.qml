import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root

    // True when any MPRIS player is currently playing
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)

    implicitWidth: content.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Tracks clock.date normally; immediately snaps to real time on wake
    // so a frozen post-sleep QTimer doesn't leave the clock stuck.
    property date _displayDate: clock.date
    Connections {
        target: clock
        function onDateChanged() { root._displayDate = clock.date }
    }
    Connections {
        target: SleepWatcher
        function onWoke() { root._displayDate = new Date() }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 0

        // // Waveform: collapses to zero width when nothing is playing
        // Item {
        //     id: wave
        //     height: 16
        //     width: root.playing ? 28 : 0   // 18px of bars + 8px gap
        //     opacity: root.playing ? 1 : 0
        //     clip: true
        //     anchors.verticalCenter: parent.verticalCenter
        //     Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        //     Behavior on opacity { NumberAnimation { duration: 200 } }
        //     Row {
        //         spacing: 1
        //         height: parent.height
        //         Repeater {
        //             // Per-bar cycle durations (ms) so the bars drift out of sync
        //             model: [380, 520, 440, 600]
        //             Rectangle {
        //                 required property int modelData
        //                 required property int index
        //                 width: 3
        //                 height: 3
        //                 radius: width / 2
        //                 y: (parent.height - height) / 2
        //                 color: Theme.foreground
        //                 SequentialAnimation on height {
        //                     running: root.playing
        //                     loops: Animation.Infinite
        //                     NumberAnimation {
        //                         to: 16 - (index % 2) * 4
        //                         duration: modelData
        //                         easing.type: Easing.InOutSine
        //                     }
        //                     NumberAnimation {
        //                         to: 3 + (index % 3) * 2
        //                         duration: modelData
        //                         easing.type: Easing.InOutSine
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }

        Text {
            id: lbl
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root._displayDate, "ddd MMM dd  hh:mm AP")
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Theme.foreground
        }
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
        onClicked: calendar.toggle()
    }

    CalendarPopup {
        id: calendar
        anchorItem: root
    }
}

