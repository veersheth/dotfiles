import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Custom-rendered tray menu: reads a tray item's DBus menu through
// QsMenuOpener and draws it in the shared popup card. One instance serves
// every tray icon; openFor() re-anchors it. Submenus expand inline.
//
// Designed to float beside the tray popup without closing it.
// grabFocus:false keeps the tray popup's focus grab alive.
BarPopup {
    id: root

    property var menuHandle: null
    contentPadding: 12
    property real trayContentWidth: 220 + 2 * contentPadding   // must match sibling tray popup contentWidth

    contentWidth:  220 + 2 * contentPadding
    contentHeight: col.implicitHeight + 2 * contentPadding

    // Don't steal focus from the tray popup; mouse clicks still reach us.
    grabFocus: false
    // keyboardFocus: None prevents the compositor from giving us keyboard
    // focus, which would clear the tray popup's HyprlandFocusGrab and
    // cause both windows to immediately collapse.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Position to the RIGHT of the tray popup.
    // trayContentWidth / 2 is the half-width of the sibling tray popup
    // (no extra flare padding in the new rectangle-based BarPopup).
    WlrLayershell.margins.left: {
        if (!anchorItem) return 0;
        const track     = anchorItem.x;
        const mid       = anchorItem.mapToGlobal(anchorItem.width / 2, 0).x;
        const sx        = screen?.x ?? 0;
        const trayRight = (mid - sx) + trayContentWidth / 2;
        return Math.max(4, Math.round(trayRight + 4));
    }

    // Delay showing until DBus delivers the initial menu items, so the enter
    // animation targets the correct height instead of morphing up from empty.
    Timer {
        id: showDelay
        interval: 60
        onTriggered: root.shown = true
    }

    function openFor(item, menu) {
        if (shown) {
            if (anchorItem === item) {
                close();
            } else {
                anchorItem = item;
                menuHandle = menu;
            }
            return;
        }
        // the click that dismissed the previous grab lands here too; only
        // swallow it when it was aimed at the icon whose menu just closed
        if (Date.now() - dismissedAt < 150 && anchorItem === item)
            return;
        anchorItem = item;
        menuHandle = menu;
        showDelay.restart()
    }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    component MenuEntry: Rectangle {
        id: entry
        required property var modelData
        property bool expanded: false
        property real indent: 0

        readonly property bool isCheckable:
            modelData.buttonType !== QsMenuButtonType.None

        Layout.fillWidth: true
        Layout.leftMargin: indent
        implicitWidth: entryRow.implicitWidth + 24
        implicitHeight: modelData.isSeparator ? 9 : 30
        radius: Theme.smallRadius
        color: !modelData.isSeparator && entryMouse.containsMouse && modelData.enabled
            ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }

        // separator: a hairline instead of a row
        Rectangle {
            visible: entry.modelData.isSeparator
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; margins: 4 }
            height: Theme.borderWidth
            color: Theme.border
        }

        RowLayout {
            id: entryRow
            visible: !entry.modelData.isSeparator
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 10
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Text {
                visible: entry.isCheckable
                text: entry.modelData.checkState === Qt.Checked
                    ? (entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "󰐾" : "󰄲")
                    : (entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "󰄰" : "󰄱")
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize - 1
                color: entry.modelData.checkState === Qt.Checked
                    ? Theme.blue : Qt.alpha(Theme.foreground, 0.6)
            }

            IconImage {
                visible: entry.modelData.icon !== ""
                implicitSize: 16
                source: entry.modelData.icon
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 120
                elide: Text.ElideRight
                text: entry.modelData.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                color: Qt.alpha(Theme.foreground, entry.modelData.enabled ? 1 : 0.35)
            }

            Text {
                visible: entry.modelData.hasChildren
                text: "󰅂"
                rotation: entry.expanded ? 90 : 0
                font.family: Theme.nerdFont
                font.pixelSize: Theme.iconSize - 2
                color: Qt.alpha(Theme.foreground, 0.6)

                Behavior on rotation { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !entry.modelData.isSeparator && entry.modelData.enabled
            onClicked: {
                if (entry.modelData.hasChildren) {
                    entry.expanded = !entry.expanded;
                } else {
                    entry.modelData.triggered();
                    root.close();
                }
            }
        }
    }

    CommonList {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 1

        Repeater {
            model: opener.children

            delegate: ColumnLayout {
                id: entryGroup
                required property var modelData
                Layout.fillWidth: true
                spacing: 1

                MenuEntry {
                    id: topEntry
                    modelData: entryGroup.modelData
                }

                // inline submenu, one level deep — plenty for tray menus
                QsMenuOpener {
                    id: subOpener
                    menu: topEntry.expanded ? entryGroup.modelData : null
                }

                Repeater {
                    model: subOpener.children
                    delegate: MenuEntry {
                        indent: 16
                    }
                }
            }
        }

        // some menus populate async over DBus; hold the card open meanwhile
        Text {
            visible: opener.children.values.length === 0
            Layout.margins: 8
            text: "No menu items"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Qt.alpha(Theme.foreground, 0.5)
        }
    }
}
