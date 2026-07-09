import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Date + time pill. Click for the calendar popup.
Pill {
    id: root

    clickable: true
    onClicked: calendar.toggle()

    CalendarPopup {
        id: calendar
        anchorItem: root
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        // "Sun Jul 04  14:20"
        text: Qt.formatDateTime(clock.date, "ddd MMM dd  HH:mm")
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        color: Theme.foreground
    }
}
