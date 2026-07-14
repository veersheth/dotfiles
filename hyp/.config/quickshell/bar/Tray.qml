import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.bar.popups

// Single chevron in the bar; click to open a popup listing every tray app.
Item {
    id: root
    visible: SystemTray.items.values.length > 0
    Layout.alignment: Qt.AlignVCenter
    implicitWidth:  chevron.implicitWidth + 20
    implicitHeight: Theme.pillHeight

    // shared context-menu popup, re-anchored per item
    TrayMenuPopup { id: trayMenu }

    // ── Chevron button ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Theme.hover
        opacity: hitArea.containsMouse || trayPopup.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
        id: chevron
        anchors.centerIn: parent
        text: "󰅀"
        font.family: Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: trayPopup.shown
            ? Theme.foreground
            : Qt.alpha(Theme.foreground, 0.55)
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }

    BarHitArea {
        id: hitArea
        hoverEnabled: true
        onClicked: trayPopup.toggle()
    }

    // ── Tray popup ─────────────────────────────────────────────────────
    BarPopup {
        id: trayPopup
        anchorItem: root
        contentWidth:  240
        contentHeight: trayCol.implicitHeight + 20

        ColumnLayout {
            id: trayCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
            spacing: 2

            Repeater {
                model: SystemTray.items

                Rectangle {
                    id: trayRow
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: rowMo.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 10

                        IconImage {
                            id: rowIcon
                            implicitWidth: 16; implicitHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: trayRow.modelData.icon
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: (trayRow.modelData.title
                                || trayRow.modelData.id
                                || "").replace(/[-_]/g, " ")
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.foreground
                        }

                        // menu indicator
                        Text {
                            visible: trayRow.modelData.hasMenu
                            text: "›"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: Qt.alpha(Theme.foreground, 0.35)
                        }
                    }

                    MouseArea {
                        id: rowMo
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton
                                    || trayRow.modelData.onlyMenu) {
                                if (trayRow.modelData.hasMenu) {
                                    trayPopup.close();
                                    trayMenu.openFor(root, trayRow.modelData.menu);
                                }
                            } else {
                                trayRow.modelData.activate();
                                trayPopup.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
