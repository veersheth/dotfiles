import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common

// Auto-hiding bottom dock. Leaks from the bottom screen edge like the bar
// popups: a canvas card that morphs from a small nub into the full dock,
// with concave flares melting into the edge.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root
        required property var modelData
        screen: modelData

        property bool dockShown: false

        // 0 → hidden nub, 1 → full card (same morph as LeakCard/BarPopup)
        property real progress: 0
        function lerp(a, b, t) { return a + (b - a) * t }

        // Pinned apps: appId = wayland app_id (case-insensitive match),
        // exec = launch command, icon = icon theme name.
        readonly property var pinned: [
            { appId: "Alacritty", exec: "alacritty", icon: "Alacritty" },
            { appId: "firefox",   exec: "firefox",   icon: "firefox"   },
            { appId: "spotify",   exec: "spotify",   icon: "spotify"   }
        ]

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

        readonly property int  cardH:  54 + Theme.dockPadding * 2
        readonly property int  cardW:  iconRow.implicitWidth + Theme.dockPadding * 2
        readonly property int  flare:  14
        readonly property real startW: 110
        readonly property real startH: 14
        readonly property real drawW:  lerp(startW, cardW, progress)
        readonly property real drawH:  lerp(startH, cardH, progress)

        // Hovered slot for the floating name label (single shared tip —
        // per-slot labels would be clipped by the morphing card rect)
        property int  hoverIdx: -1
        property real tipX: 0

        anchors { bottom: true; left: true; right: true }
        // Card plus headroom for the name label floating above it
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
            target: root; property: "progress"
            to: 1; duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
        NumberAnimation {
            id: exitAnim
            target: root; property: "progress"
            to: 0; duration: 160; easing.type: Easing.InCubic
        }

        // Union of edge strip + card so the strip keeps receiving hover while
        // the dock is shown. Masking to the card alone made a pointer parked
        // at the screen edge count as "outside", causing hide/reveal flicker.
        mask: Region {
            item: hotStrip
            Region { item: cardClip }
        }

        // 2px hot strip along the very bottom edge — reveals the dock and
        // keeps it open while the pointer stays on the edge.
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

        Item {
            id: slider
            anchors.horizontalCenter: parent.horizontalCenter
            // extra slack so the OutBack overshoot doesn't clip
            width: root.cardW + root.flare * 2 + 24
            height: parent.height
            opacity: Math.min(1, root.progress * 4)
            visible: root.progress > 0

            // Leak shape: card flush with the bottom edge, rounded top
            // corners, concave flares where the sides meet the edge.
            Canvas {
                anchors.fill: parent

                readonly property real cw: root.drawW
                readonly property real chh: root.drawH
                onCwChanged:  requestPaint()
                onChhChanged: requestPaint()
                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const m    = root.flare;
                    const dw   = root.drawW;
                    const dh   = root.drawH;
                    const x0   = (width - dw) / 2;
                    const x1   = x0 + dw;
                    const yTop = height - dh;
                    const yBot = height;
                    const br   = Math.min(
                        root.lerp(root.startH / 2, Theme.popupRadius, root.progress),
                        dh / 2, dw / 2);

                    ctx.beginPath();
                    ctx.moveTo(x0 - m, yBot);
                    ctx.arc(x0 - m, yBot - m, m, Math.PI / 2, 0, true);
                    ctx.lineTo(x0, yTop + br);
                    ctx.arc(x0 + br, yTop + br, br, Math.PI, 3 * Math.PI / 2, false);
                    ctx.lineTo(x1 - br, yTop);
                    ctx.arc(x1 - br, yTop + br, br, -Math.PI / 2, 0, false);
                    ctx.lineTo(x1, yBot - m);
                    ctx.arc(x1 + m, yBot - m, m, Math.PI, Math.PI / 2, true);
                    ctx.closePath();

                    ctx.fillStyle   = Theme.dockBackground;
                    ctx.fill();
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth   = Theme.borderWidth;
                    ctx.stroke();
                }
            }

            // Floating name label for the hovered icon (outside the clip)
            Rectangle {
                x: root.tipX - width / 2
                y: slider.height - root.cardH - 34
                width: tipText.implicitWidth + 16
                height: 24
                radius: 12
                color: Theme.surface
                border.width: Theme.borderWidth
                border.color: Theme.border
                opacity: root.hoverIdx >= 0 && root.progress > 0.95 ? 1 : 0
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

            // Content clipped to the morphing card rect
            Item {
                id: cardClip
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width: root.drawW
                height: root.drawH
                clip: true

                // HoverHandler instead of MouseArea: hover delivery to a
                // MouseArea stops when the pointer moves onto a child
                // MouseArea (the icons). HoverHandler is non-exclusive.
                HoverHandler {
                    id: cardHover
                    onHoveredChanged: hovered ? hideTimer.stop() : hideTimer.restart()
                }

                Item {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width: root.cardW
                    height: root.cardH
                    opacity: Math.max(0, (root.progress - 0.35) / 0.65)

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

                                readonly property var toplevel: root.toplevelFor(modelData.appId)
                                readonly property bool running: toplevel !== null
                                readonly property string iconSrc: Quickshell.iconPath(modelData.icon, true)

                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 46
                                implicitHeight: 54

                                // Hover highlight behind the icon
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: icon.y - 2
                                    width: 46; height: 46; radius: 12
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
                                    width: 42; height: 42; radius: 11
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

                                // Running indicator
                                Rectangle {
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                    width: 4; height: 4; radius: 2
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
                                            root.tipX = slot.mapToItem(slider, slot.width / 2, 0).x;
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
    }
}
