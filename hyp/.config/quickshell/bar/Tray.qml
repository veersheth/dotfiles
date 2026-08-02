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
        // text: "󰅀"
        text: ""
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
        onEntered: tip.show(root)
        onExited:  tip.hide()
        onClicked: { tip.hide(); trayPopup.toggle() }
    }

    BarTooltip {
        id: tip
        contentWidth:  tipText.implicitWidth + 24
        contentHeight: tipText.implicitHeight + 14
        Text {
            id: tipText
            anchors.centerIn: parent
            text: "System tray"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    // ── Tray popup ─────────────────────────────────────────────────────
    BarPopup {
        id: trayPopup
        anchorItem: root
        contentPadding: 12
        contentWidth:  220 + 2 * contentPadding
        contentHeight: trayCol.implicitHeight + 2 * contentPadding
        // Include trayMenu in the same grab so Hyprland delivers hover/pointer
        // events to trayMenu's surface while the grab is active.
        extraGrabWindow: trayMenu
        // Close the context menu whenever the tray popup closes.
        onShownChanged: if (!shown) trayMenu.close()

        CommonList {
            id: trayCol
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 2

            Repeater {
                model: SystemTray.items

                Item {
                    id: trayRow
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // ── Icon + name button ─────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.smallRadius
                            color: leftMo.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 8 }
                                spacing: 10

                                IconImage {
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
                            }

                            MouseArea {
                                id: leftMo
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: {
                                    if (trayRow.modelData.hasMenu) {
                                        if (trayMenu.shown)
                                            trayMenu.menuHandle = trayRow.modelData.menu
                                        else
                                            trayMenu.openFor(root, trayRow.modelData.menu)
                                    } else {
                                        trayMenu.close()
                                    }
                                }
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton
                                            || trayRow.modelData.onlyMenu) {
                                        if (trayRow.modelData.hasMenu)
                                            trayMenu.openFor(root, trayRow.modelData.menu)
                                    } else {
                                        trayRow.modelData.activate()
                                    }
                                }
                            }
                        }

                        // ── Arrow button ───────────────────────────────
                        Rectangle {
                            visible: trayRow.modelData.hasMenu
                            implicitWidth: 26
                            Layout.fillHeight: true
                            radius: Theme.smallRadius
                            color: arrowMo.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: "›"
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                color: arrowMo.containsMouse
                                    ? Theme.foreground
                                    : Qt.alpha(Theme.foreground, 0.35)
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: arrowMo
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: trayMenu.openFor(root, trayRow.modelData.menu)
                            }
                        }
                    }
                }
            }
        }
    }
}
