import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

Item {
    id: root

    implicitWidth: lbl.implicitWidth + 20
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

    Text {
        id: lbl
        anchors.centerIn: parent
        text: Qt.formatDateTime(root._displayDate, "ddd MMM dd  hh:mm AP")
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
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
        onClicked: calendar.toggle()
    }

    CalendarPopup {
        id: calendar
        anchorItem: root
    }
}
