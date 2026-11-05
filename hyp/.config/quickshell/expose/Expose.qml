import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.common
import qs.wallpaper
import "Layout.js" as Layout

Scope {
    id: root

    property var captures: []
    property var targets: ({})
    property var closedAddresses: []
    property bool geometryReady: false
    property bool overlayShown: false
    property string frontAddress: ""
    property string hoveredAddress: ""
    property real hoverCursorX: 0
    property real hoverCursorY: 0
    property int rounding: 0
    property int borderSize: 0
    property color activeBorder: "transparent"
    property color inactiveBorder: "transparent"

    function raiseCapture(capture, cursorX, cursorY) {
        frontAddress = capture.address
        const selector = 'address:0x' + capture.address
        Hyprland.dispatch('hl.dsp.focus({ window = "' + selector + '" })')
        Hyprland.dispatch('hl.dsp.window.alter_zorder({ mode = "top", window = "'
                          + selector + '" })')
        if (Number.isFinite(cursorX) && Number.isFinite(cursorY))
            Hyprland.dispatch('hl.dsp.cursor.move({ x = ' + Math.round(cursorX)
                              + ', y = ' + Math.round(cursorY) + ' })')
        BarState.exposeActive = false
    }

    function setHovered(capture, cursorX, cursorY) {
        hoveredAddress = capture.address
        hoverCursorX = cursorX
        hoverCursorY = cursorY
    }

    function clearHovered(address) {
        if (hoveredAddress === address) hoveredAddress = ""
    }

    function toggle() {
        if (BarState.exposeActive && hoveredAddress !== "") {
            const capture = captures.find(c => c.address === hoveredAddress)
            if (capture && !closedAddresses.includes(capture.address)) {
                raiseCapture(capture, hoverCursorX, hoverCursorY)
                return
            }
        }
        BarState.exposeActive = !BarState.exposeActive
    }

    function closeHovered() {
        if (!BarState.exposeActive) {
            Hyprland.dispatch('hl.dsp.window.close()')
            return
        }
        const capture = captures.find(c => c.address === hoveredAddress)
        if (capture && !closedAddresses.includes(capture.address))
            capture.handle.close()
    }

    function reflowCaptures() {
        const remaining = captures.filter(c => !closedAddresses.includes(c.address))
        Layout.spreadCaptures(remaining, Hyprland.monitors.values)
        const nextTargets = {}
        for (const capture of remaining)
            nextTargets[capture.address] = {
                x: capture.targetX, y: capture.targetY,
                width: capture.targetWidth, height: capture.targetHeight
            }
        targets = nextTargets
    }

    function close() { BarState.exposeActive = false }

    function removeCapture(address) {
        if (closedAddresses.includes(address)) return
        closedAddresses = closedAddresses.concat([address])
        clearHovered(address)
        reflowCaptures()
    }

    IpcHandler {
        target: "expose"
        function toggle(): void { root.toggle() }
        function open(): void { BarState.exposeActive = true }
        function close(): void { root.close() }
        function closeHovered(): void { root.closeHovered() }
    }

    Connections {
        target: BarState
        function onExposeActiveChanged() {
            if (BarState.exposeActive) {
                const resuming = closeTimer.running && root.geometryReady
                closeTimer.stop()
                root.overlayShown = true
                if (resuming) return
                root.geometryReady = false
                root.captures = []
                root.targets = ({})
                root.closedAddresses = []
                root.frontAddress = ""
                root.hoveredAddress = ""
                Hyprland.refreshMonitors()
                Hyprland.refreshWorkspaces()
                clientsProcess.running = true
                decorationProcess.running = true
            } else {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 320
        repeat: false
        onTriggered: {
            root.overlayShown = false
            root.geometryReady = false
            root.captures = []
            root.targets = ({})
            root.closedAddresses = []
            root.hoveredAddress = ""
        }
    }

    Process {
        id: decorationProcess
        command: ["hyprctl", "-j", "--batch", "getoption decoration:rounding;getoption general:border_size;getoption general:col.active_border;getoption general:col.inactive_border"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const values = text.match(/\{[^\n]*\}/g).map(value => JSON.parse(value))
                    root.rounding = values[0].int
                    root.borderSize = values[1].int
                    root.activeBorder = "#" + values[2].gradient.split(" ")[0]
                    root.inactiveBorder = "#" + values[3].gradient.split(" ")[0]
                } catch (error) {
                    console.warn("Expose: could not read Hyprland decoration:", error)
                }
            }
        }
    }

    Process {
        id: clientsProcess
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!BarState.exposeActive) return

                try {
                    const clients = JSON.parse(text)
                    const monitors = Hyprland.monitors.values
                    const toplevels = Hyprland.toplevels.values
                    const captures = []

                    for (const client of clients) {
                        if (!client.mapped || client.hidden || !client.at || !client.size)
                            continue

                        const monitor = monitors.find(m => m.id === client.monitor)
                        if (!monitor) continue

                        const workspaceId = client.workspace?.id
                        if (workspaceId === undefined || workspaceId < 0 && client.workspace?.name?.startsWith("special:")) continue

                        const address = client.address.replace(/^0x/, "")
                        const toplevel = toplevels.find(t => t.address === address)
                        if (!toplevel?.wayland) continue

                        captures.push({
                            address: address,
                            className: client.class ?? "",
                            monitorId: monitor.id,
                            workspaceId: workspaceId,
                            x: client.at[0] - monitor.x,
                            y: client.at[1] - monitor.y,
                            width: client.size[0],
                            height: client.size[1],
                            handle: toplevel.wayland
                        })
                    }

                    root.captures = captures
                    root.reflowCaptures()
                    root.geometryReady = true
                } catch (error) {
                    console.warn("Expose: could not read window geometry:", error)
                }
            }
        }
    }

    Variants {
        model: Compositor.hyprland ? Quickshell.screens : []

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property var workspaceEntries: Hyprland.workspaces.values.filter(
                workspace => workspace.monitor?.name === monitor?.name
                    && !workspace.name.startsWith("special:"))
            readonly property int activePageIndex: Math.max(0, workspaceEntries.findIndex(
                workspace => workspace.id === monitor?.activeWorkspace?.id))
            onActivePageIndexChanged: root.hoveredAddress = ""
            readonly property var screenCaptures: root.captures.filter(
                capture => capture.monitorId === monitor?.id)
            property bool ready: false
            property bool spread: false
            property bool pageTransitionsEnabled: false
            property bool otherPagesEnabled: false
            property int refreshIndex: 0
            onReadyChanged: startSpread()

            function startSpread() {
                if (!BarState.exposeActive || !ready || spread) return
                spread = true
                pageTransitionTimer.restart()
            }

            function goPage(direction) {
                if (!BarState.exposeActive || pageCooldown.running) return
                const next = workspaceEntries[activePageIndex + direction]
                if (!next) return
                root.hoveredAddress = ""
                pageCooldown.restart()
                next.activate()
            }

            Timer { id: pageCooldown; interval: 280 }

            Connections {
                target: BarState
                function onExposeActiveChanged() {
                    if (BarState.exposeActive) {
                        overlay.pageTransitionsEnabled = false
                        overlay.otherPagesEnabled = false
                        pageTransitionTimer.stop()
                        overlay.startSpread()
                    } else {
                        pageTransitionTimer.stop()
                        overlay.pageTransitionsEnabled = false
                        overlay.otherPagesEnabled = false
                        overlay.spread = false
                    }
                }
            }

            Timer {
                id: pageTransitionTimer
                interval: 310
                repeat: false
                onTriggered: if (BarState.exposeActive) {
                    overlay.pageTransitionsEnabled = true
                    overlay.otherPagesEnabled = true
                }
            }

            // Refresh one preview per tick. The total capture rate stays bounded
            // even when a workspace contains many windows.
            Timer {
                interval: 85
                repeat: true
                running: BarState.exposeActive && overlay.spread
                onTriggered: {
                    const count = overlay.screenCaptures.length
                    for (let offset = 0; offset < count; offset++) {
                        const index = (overlay.refreshIndex + offset) % count
                        const capture = overlay.screenCaptures[index]
                        if (capture.workspaceId !== overlay.monitor?.activeWorkspace?.id
                                || root.closedAddresses.includes(capture.address))
                            continue
                        captureRepeater.itemAt(index)?.refreshFrame()
                        overlay.refreshIndex = (index + 1) % count
                        break
                    }
                }
            }

            function updateReady() {
                if (!root.geometryReady || (!WallpaperService.isColor
                        && WallpaperService.imagePath !== ""
                        && wallpaperImage.status !== Image.Ready)) {
                    ready = false
                    return
                }
                for (let i = 0; i < screenCaptures.length; i++) {
                    if (root.closedAddresses.includes(screenCaptures[i].address)
                            || screenCaptures[i].workspaceId !== monitor?.activeWorkspace?.id)
                        continue
                    if (!captureRepeater.itemAt(i)?.captureReady) {
                        ready = false
                        return
                    }
                }
                ready = true
            }

            onScreenCapturesChanged: Qt.callLater(updateReady)

            Connections {
                target: root
                function onGeometryReadyChanged() { overlay.updateReady() }
            }

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            visible: root.overlayShown
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:expose"
            WlrLayershell.keyboardFocus: root.overlayShown && overlay.monitor?.focused
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Shortcut { sequence: "Escape"; enabled: root.overlayShown; onActivated: root.close() }

            Rectangle {
                anchors.fill: parent
                color: "#22000000"
                opacity: root.overlayShown && !overlay.ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 90 } }
            }

            Item {
                anchors.fill: parent
                // Keep the scene rendering so ScreencopyView can receive its
                // first frame, without showing a wallpaper-only transition.
                opacity: overlay.ready ? 1 : 0.001

                Rectangle {
                    anchors.fill: parent
                    color: WallpaperService.isColor ? WallpaperService.colorValue : "black"
                }

                Image {
                    id: wallpaperImage
                    anchors.fill: parent
                    visible: !WallpaperService.isColor
                    source: WallpaperService.imagePath !== ""
                            ? "file://" + WallpaperService.imagePath : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    onStatusChanged: overlay.updateReady()
                }

                MouseArea {
                    anchors.fill: parent
                }

                WheelHandler {
                    target: null
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    orientation: Qt.Horizontal
                    onWheel: event => {
                        const delta = event.pixelDelta.x || event.angleDelta.x
                        if (Math.abs(delta) >= 8) overlay.goPage(delta < 0 ? 1 : -1)
                    }
                }

                Item {
                    id: pageTrack
                    width: parent.width
                    height: parent.height
                    x: -overlay.activePageIndex * overlay.width
                    Behavior on x {
                        enabled: overlay.pageTransitionsEnabled
                        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                    }

                Repeater {
                    id: captureRepeater
                    model: overlay.screenCaptures
                    onItemAdded: Qt.callLater(overlay.updateReady)

                    Item {
                        id: preview
                        required property var modelData
                        readonly property bool captureReady: captureView.hasContent
                        property bool initialized: false
                        Component.onCompleted: initialized = true
                        z: modelData.address === root.frontAddress ? 1 : 0
                        readonly property int pageIndex: overlay.workspaceEntries.findIndex(
                            workspace => workspace.id === modelData.workspaceId)
                        readonly property bool currentPage: modelData.workspaceId === overlay.monitor?.activeWorkspace?.id
                        readonly property bool nearbyPage: Math.abs(pageIndex - overlay.activePageIndex) <= 1
                        function refreshFrame() { captureView.captureFrame() }
                        visible: nearbyPage && !root.closedAddresses.includes(modelData.address)
                        x: pageIndex * overlay.width + (overlay.spread ? (root.targets[modelData.address]?.x ?? modelData.x) : modelData.x)
                        y: overlay.spread ? (root.targets[modelData.address]?.y ?? modelData.y) : modelData.y
                        width: overlay.spread ? (root.targets[modelData.address]?.width ?? modelData.width) : modelData.width
                        height: overlay.spread ? (root.targets[modelData.address]?.height ?? modelData.height) : modelData.height

                        Behavior on x {
                            enabled: preview.initialized && preview.currentPage
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            enabled: preview.initialized && preview.currentPage
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                        Behavior on width {
                            enabled: preview.initialized && preview.currentPage
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                        Behavior on height {
                            enabled: preview.initialized && preview.currentPage
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }

                        Connections {
                            target: preview.modelData.handle
                            function onClosed() { root.removeCapture(preview.modelData.address) }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: root.rounding * Math.min(preview.width / preview.modelData.width,
                                                    preview.height / preview.modelData.height)
                            color: "transparent"
                            contentUnderBorder: true
                            border.width: root.borderSize
                            border.color: (root.hoveredAddress !== ""
                                ? root.hoveredAddress === preview.modelData.address
                                : preview.modelData.handle.activated)
                                ? root.activeBorder : root.inactiveBorder
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            ScreencopyView {
                                id: captureView
                                anchors.fill: parent
                                captureSource: preview.currentPage
                                    || overlay.otherPagesEnabled && preview.nearbyPage
                                    ? preview.modelData.handle : null
                                live: false
                                onCaptureSourceChanged: if (captureSource) captureFrame()
                                onHasContentChanged: overlay.updateReady()
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.setHovered(preview.modelData,
                                overlay.monitor.x + pageTrack.x + preview.x + mouseX,
                                overlay.monitor.y + preview.y + mouseY)
                            onPositionChanged: mouse => root.setHovered(preview.modelData,
                                overlay.monitor.x + pageTrack.x + preview.x + mouse.x,
                                overlay.monitor.y + preview.y + mouse.y)
                            onExited: root.clearHovered(preview.modelData.address)
                            onClicked: mouse => root.raiseCapture(
                                preview.modelData,
                                overlay.monitor.x + pageTrack.x + preview.x + mouse.x,
                                overlay.monitor.y + preview.y + mouse.y)
                        }
                    }
                }
                }

                Item {
                    id: workspaceStrip
                    width: Math.min(parent.width - 32,
                        20 + overlay.workspaceEntries.length * 142
                        + Math.max(0, overlay.workspaceEntries.length - 1) * 12)
                    height: 120
                    readonly property real thumbWidth: overlay.workspaceEntries.length > 0
                        ? Math.min(142, (width - 20
                            - (overlay.workspaceEntries.length - 1) * 12)
                            / overlay.workspaceEntries.length) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: overlay.spread ? 16 : -height - 16
                    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 19
                        color: "#dc111418"
                        border.width: 1
                        border.color: "#33ffffff"
                    }

                    Row {
                        id: thumbRow
                        anchors.centerIn: parent
                        spacing: 12
                        Repeater {
                            model: overlay.workspaceEntries
                            Item {
                                id: thumb
                                required property var modelData
                                width: workspaceStrip.thumbWidth
                                height: 100

                                ClippingRectangle {
                                    id: thumbFrame
                                    width: parent.width
                                    height: 76
                                    radius: 10
                                    color: WallpaperService.isColor
                                        ? WallpaperService.colorValue : "#111418"
                                    border.width: 1
                                    border.color: thumbMouse.containsMouse
                                        ? "#aaffffff" : "#55ffffff"
                                    contentUnderBorder: true

                                    Image {
                                        anchors.fill: parent
                                        visible: !WallpaperService.isColor
                                        source: wallpaperImage.source
                                        fillMode: Image.PreserveAspectCrop
                                        opacity: 0.78
                                    }
                                    Rectangle { anchors.fill: parent; color: "#33000000" }
                                    Repeater {
                                        model: overlay.screenCaptures.filter(c => c.workspaceId === thumb.modelData.id
                                            && !root.closedAddresses.includes(c.address))
                                        Rectangle {
                                            required property var modelData
                                            x: modelData.x * thumbFrame.width / overlay.width
                                            y: modelData.y * thumbFrame.height / overlay.height
                                            width: Math.max(3, modelData.width * thumbFrame.width / overlay.width)
                                            height: Math.max(3, modelData.height * thumbFrame.height / overlay.height)
                                            color: "#e21b2026"
                                            border.width: 1
                                            border.color: "#99c3ccd8"
                                            radius: 2
                                        }
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: thumb.modelData.name
                                    elide: Text.ElideRight
                                    color: overlay.monitor?.activeWorkspace?.id === thumb.modelData.id
                                        ? "#ffffff" : "#c5cbd2"
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: overlay.monitor?.activeWorkspace?.id === thumb.modelData.id
                                        ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: thumbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: thumb.modelData.activate()
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: thumbRow.x + overlay.activePageIndex * (workspaceStrip.thumbWidth + thumbRow.spacing) - 3
                        y: thumbRow.y - 3
                        width: workspaceStrip.thumbWidth + 6
                        height: 82
                        radius: 13
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.blue
                        Behavior on x {
                            enabled: overlay.pageTransitionsEnabled
                            NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
