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
        // "Sun Jul 04  02:20 PM"
        text: Qt.formatDateTime(clock.date, "ddd MMM dd  hh:mm AP")
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        color: Theme.foreground
    }
}
