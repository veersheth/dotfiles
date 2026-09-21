import Quickshell
import Quickshell.Services.Mpris
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

    contentWidth: mainRow.implicitWidth + 44
    contentHeight: mainRow.implicitHeight + 44

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
        radius: Theme.smallRadius
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

    // ── Media player tracking ────────────────────────────────────────────
    QtObject {
        id: mediaHost
        property var _lastPlayer: null
        readonly property var player: {
            const players = Mpris.players.values
            if (players.length === 0) return null
            for (const p of players)
                if (p.playbackState === MprisPlaybackState.Playing) {
                    _lastPlayer = p; return p
                }
            if (_lastPlayer !== null)
                for (const p of players)
                    if (p === _lastPlayer) return p
            if (players.length > 0) { _lastPlayer = players[0]; return players[0] }
            return null
        }
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 40

        ColumnLayout {
        id: col
        spacing: 10
        Layout.alignment: Qt.AlignTop

        // ── Header: ⇑ ↑ Month Year ↓ ⇓ ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            NavButton { label: "󰄿"; onActivated: root.addMonths(-12) }
            NavButton { label: ""; onActivated: root.addMonths(-1) }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 26
                radius: Theme.smallRadius
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

            NavButton { label: ""; onActivated: root.addMonths(1) }
            NavButton { label: "󰄼"; onActivated: root.addMonths(12) }

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
        Item {
            Layout.preferredWidth: 7 * root.cellW + 6 * 2
            Layout.preferredHeight: 6 * root.cellH + 5 * 2

            ListView {
            id: monthList

            readonly property int baseIndex: root.minYear * 12

            anchors.fill: parent
            clip: true
            interactive: false
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
                            radius: Theme.smallRadius
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

            // Transparent overlay: catches wheel/touchpad events above the
            // ListView so Flickable can't intercept them. Plain Item — no
            // MouseArea — so day clicks still pass through.
            Item {
                anchors.fill: parent
                WheelHandler {
                    target: null
                    property real accum: 0
                    onWheel: event => {
                        accum += event.angleDelta.y
                        if (Math.abs(accum) >= 120) {
                            root.addMonths(accum < 0 ? 1 : -1)
                            accum = 0
                        }
                    }
                }
            }
        }
        // ── Analog clock ─────────────────────────────────────────────
        AnalogClock {
            implicitWidth:  220
            implicitHeight: 220
            Layout.alignment: Qt.AlignHCenter
            running: root.shown
        }

    }   // ColumnLayout col

        // ── Media ────────────────────────────────────────────────────
        // Slides in when a player is present; collapses + fades when gone.
        Item {
            id: mediaSection
            readonly property bool hasPlayer: mediaHost.player !== null

            // Animated width so the popup resizes smoothly
            property real _w: hasPlayer ? 300 : 0
            Behavior on _w { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }

            Layout.preferredWidth: _w
            Layout.preferredHeight: mediaCard.implicitHeight
            Layout.alignment: Qt.AlignTop
            clip: true
            visible: _w > 0

            MediaCard {
                id: mediaCard
                x: 16           // indent past the divider
                width: 284
                player: mediaHost.player
                active: root.shown && mediaHost.player !== null

                opacity: mediaSection.hasPlayer ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }

    }   // RowLayout mainRow
}
