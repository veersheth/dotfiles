import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common

// Auto-hiding bottom dock. Slides up from the screen edge as a rounded
// rectangle; scales from Item.Bottom so it appears to emerge from the edge.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root
        required property var modelData
        screen: modelData

        property bool dockShown: false

        // Pinned apps: appId = wayland app_id (case-insensitive match),
        // exec = launch command, icon = icon theme name.
        readonly property var pinned: []

        // Pinned entries first, then running apps that aren't pinned.
        readonly property var entries: {
            const tops = ToplevelManager.toplevels.values;
            const list = pinned.map(p => ({ appId: p.appId, exec: p.exec, icon: p.icon }));
            for (const t of tops) {
                const id = t.appId ?? "";
                if (id === "") continue;
                if (!list.some(e => e.appId.toLowerCase() === id.toLowerCase()))
                    list.push({ appId: id, exec: id.toLowerCase(), icon: id });
            }
            return list;
        }

        function toplevelFor(appId) {
            for (const t of ToplevelManager.toplevels.values)
                if ((t.appId ?? "").toLowerCase() === appId.toLowerCase()) return t;
            return null;
        }

        readonly property int cardH: 54 + Theme.dockPadding * 2
        readonly property int cardW: iconRow.implicitWidth + Theme.dockPadding * 2

        // Hovered slot for the floating name label above the dock
        property int  hoverIdx: -1
        property real tipX: 0

        anchors { bottom: true; left: true; right: true }
        implicitHeight: cardH + 42
        exclusiveZone: -1
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:dock"

        onDockShownChanged: {
            if (dockShown) { exitAnim.stop(); enterAnim.restart(); }
            else           { enterAnim.stop(); exitAnim.restart(); }
        }

        NumberAnimation {
            id: enterAnim
            target: card; property: "opacity"
            from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: exitAnim
            target: card; property: "opacity"
            to: 0; duration: 140; easing.type: Easing.InCubic
        }

        mask: Region {
            item: hotStrip
            Region { item: card }
        }

        // 2px hot strip along the bottom edge — reveals the dock.
        MouseArea {
            id: hotStrip
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 2
            hoverEnabled: true
            onEntered: { root.dockShown = true; hideTimer.stop(); }
            onExited:  hideTimer.restart()
        }

        Timer {
            id: hideTimer
            interval: Theme.dockHideDelay
            onTriggered: {
                if (!cardHover.hovered && !hotStrip.containsMouse)
                    root.dockShown = false;
            }
        }

        // Floating name label above the card (outside clip so it's always visible)
        Rectangle {
            x: root.tipX - width / 2
            y: parent.height - root.cardH - 32
            width: tipText.implicitWidth + 16
            height: 24
            radius: Theme.popupRadius
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: Theme.border
            opacity: root.hoverIdx >= 0 && card.scale > 0.98 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                id: tipText
                anchors.centerIn: parent
                text: {
                    if (root.hoverIdx < 0 || root.hoverIdx >= root.entries.length) return "";
                    const id = root.entries[root.hoverIdx].appId;
                    return id.charAt(0).toUpperCase() + id.slice(1);
                }
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                color: Theme.foreground
            }
        }

        Rectangle {
            id: card
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            width:  root.cardW
            height: root.cardH
            radius: Theme.radius
            color:  Theme.dockBackground
            border.color: Theme.border
            border.width: Theme.borderWidth
            opacity: 0
            clip: true

            HoverHandler {
                id: cardHover
                onHoveredChanged: hovered ? hideTimer.stop() : hideTimer.restart()
            }

            RowLayout {
                id: iconRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: root.entries

                    Item {
                        id: slot
                        required property var modelData
                        required property int index

                        readonly property var    toplevel: root.toplevelFor(modelData.appId)
                        readonly property bool   running:  toplevel !== null
                        readonly property string iconSrc:  Quickshell.iconPath(modelData.icon, true)

                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth:  46
                        implicitHeight: 54

                        // Hover highlight behind the icon
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: icon.y - 2
                            width: 46; height: 46; radius: Theme.popupRadius
                            color: Theme.hover
                            opacity: slotMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        IconImage {
                            id: icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 4
                            implicitSize: 42
                            source: slot.iconSrc
                            visible: slot.iconSrc !== ""
                        }

                        // Fallback tile when no theme icon exists
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: icon.y
                            width: 42; height: 42; radius: Theme.itemRadius
                            visible: slot.iconSrc === ""
                            color: Theme.surface
                            border.width: Theme.borderWidth
                            border.color: Theme.border
                            Text {
                                anchors.centerIn: parent
                                text: slot.modelData.appId.charAt(0).toUpperCase()
                                font.family: Theme.font
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                            }
                        }

                        // Running indicator dot
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: 4; height: 4; radius: height / 2
                            visible: slot.running
                            color: slot.toplevel?.activated ?? false
                                ? Theme.foreground
                                : Qt.alpha(Theme.foreground, 0.45)
                        }

                        MouseArea {
                            id: slotMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    root.hoverIdx = slot.index;
                                    root.tipX = slot.mapToItem(root, slot.width / 2, 0).x;
                                } else if (root.hoverIdx === slot.index) {
                                    root.hoverIdx = -1;
                                }
                            }
                            onClicked: {
                                if (slot.running) slot.toplevel.activate();
                                else Quickshell.execDetached(["sh", "-c", slot.modelData.exec]);
                            }
                        }
                    }
                }
            }
        }
    }
}
