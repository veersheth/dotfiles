import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Month calendar with a vertically scrolling month strip. Navigate with
// ‹ › (months), « » (years), or the scroll wheel; click the title to jump
// back to today.
BarPopup {
    id: root

    property var today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    property double selectedMs: -1

    // Qt convention: 1 = Monday .. 7 = Sunday; %7 maps onto JS getDay()
    readonly property int firstDow: Qt.locale().firstDayOfWeek

    readonly property int cellW: 34
    readonly property int cellH: 30

    // month strip range; keeps ListView indices manageable
    readonly property int minYear: 1900
    readonly property int maxYear: 2100

    contentWidth: col.implicitWidth + 44
    contentHeight: col.implicitHeight + 44

    // always open on the current month
    onShownChanged: if (shown) goToday()

    function goToday() {
        today = new Date();
        month = today.getMonth();
        year = today.getFullYear();
        selectedMs = -1;
    }

    function addMonths(n) {
        const total = Math.max(minYear * 12,
            Math.min(maxYear * 12 + 11, year * 12 + month + n));
        year = Math.floor(total / 12);
        month = total % 12;
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    component NavButton: Rectangle {
        property alias label: navText.text
        signal activated()

        implicitWidth: 26
        implicitHeight: 26
        radius: 6
        color: navMouse.containsMouse ? Theme.hoverStrong : "transparent"

        Text {
            id: navText
            anchors.centerIn: parent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
            color: Theme.foreground
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.activated()
        }
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 10

        WheelHandler {
            target: null
            onWheel: event => root.addMonths(event.angleDelta.y < 0 ? 1 : -1)
        }

        // ── Header: « ‹ Month Year › » ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            NavButton { label: "«"; onActivated: root.addMonths(-12) }
            NavButton { label: "‹"; onActivated: root.addMonths(-1) }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 6
                color: titleMouse.containsMouse ? Theme.hover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    color: Theme.foreground
                }

                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.goToday()
                }
            }

            NavButton { label: "›"; onActivated: root.addMonths(1) }
            NavButton { label: "»"; onActivated: root.addMonths(12) }
        }

        // ── Day-of-week labels ────────────────────────────────────────
        Row {
            spacing: 2
            Repeater {
                model: 7
                Text {
                    required property int index
                    width: root.cellW
                    horizontalAlignment: Text.AlignHCenter
                    // any week works; grid columns always start on firstDow
                    text: Qt.locale().dayName(
                        (root.firstDow - 1 + index) % 7 + 1, Locale.ShortFormat)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    color: Qt.alpha(Theme.foreground, 0.5)
                }
            }
        }

        // ── Vertically scrolling month strip ──────────────────────────
        ListView {
            id: monthList

            readonly property int baseIndex: root.minYear * 12

            Layout.preferredWidth: 7 * root.cellW + 6 * 2
            Layout.preferredHeight: 6 * root.cellH + 5 * 2
            clip: true
            interactive: false   // wheel + buttons drive it via currentIndex
            model: (root.maxYear - root.minYear + 1) * 12

            currentIndex: root.year * 12 + root.month - baseIndex
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightMoveDuration: 250
            highlightMoveVelocity: -1

            // land on the initial month without scrolling there from 1900
            Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Beginning)

            delegate: Item {
                id: monthItem
                required property int index
                readonly property int mYear: Math.floor((monthList.baseIndex + index) / 12)
                readonly property int mMonth: (monthList.baseIndex + index) % 12
                readonly property int mOffset:
                    (new Date(mYear, mMonth, 1).getDay() - root.firstDow % 7 + 7) % 7

                width: monthList.width
                height: monthList.height + 10   // gap only visible mid-scroll

                Grid {
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2

                    Repeater {
                        model: 42
                        Rectangle {
                            required property int index
                            readonly property var day: new Date(
                                monthItem.mYear, monthItem.mMonth,
                                1 - monthItem.mOffset + index)
                            readonly property bool inMonth:
                                day.getMonth() === monthItem.mMonth
                            readonly property bool isToday: root.isSameDay(day, root.today)
                            readonly property bool isSelected: day.getTime() === root.selectedMs

                            width: root.cellW
                            height: root.cellH
                            radius: 8
                            color: isToday ? Theme.blue
                                 : isSelected ? Theme.hoverStrong
                                 : dayMouse.containsMouse ? Theme.hover
                                 : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.day.getDate()
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: parent.isToday ? Font.Bold : Font.Medium
                                color: parent.isToday ? Theme.onAccent
                                     : parent.inMonth ? Theme.foreground
                                     : Qt.alpha(Theme.foreground, 0.3)
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.selectedMs = parent.day.getTime()
                            }
                        }
                    }
                }
            }
        }
    }
}
