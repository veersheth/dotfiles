import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root
    property color foreground: Theme.foreground
    property string monitorName: ""
    readonly property bool onNiri: Compositor.niri
    property var niriWorkspaces: []
    readonly property string niriScript: Qt.resolvedUrl("../scripts/niri-workspaces.sh").toString().replace("file://", "")

    Process {
        id: niriEvents
        running: root.onNiri
        command: ["bash", root.niriScript, "watch"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line)
                    if (event.WorkspacesChanged) {
                        root.niriWorkspaces = event.WorkspacesChanged.workspaces
                    } else if (event.WorkspaceActivated) {
                        const { id, focused } = event.WorkspaceActivated
                        const activated = root.niriWorkspaces.find(w => w.id === id)
                        if (!activated) return
                        root.niriWorkspaces = root.niriWorkspaces.map(w => Object.assign({}, w, {
                            is_active: w.output === activated.output ? w.id === id : w.is_active,
                            is_focused: focused ? w.id === id : w.is_focused
                        }))
                    } else if (event.WorkspaceUrgencyChanged) {
                        const { id, urgent } = event.WorkspaceUrgencyChanged
                        root.niriWorkspaces = root.niriWorkspaces.map(w =>
                            w.id === id ? Object.assign({}, w, { is_urgent: urgent }) : w)
                    }
                } catch (e) { console.warn("niri workspace event:", e) }
            }
        }
    }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.pillHeight
    radius: height / 2
    color: "transparent"
    // border.color: Theme.border
    // border.width: Theme.borderWidth
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: Qt.alpha(root.foreground, 0.13)
        opacity: pillMouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.moduleSpacing

        Repeater {
            model: Compositor.mango
                ? Mango.tagsFor(root.monitorName)
                : root.onNiri
                ? root.niriWorkspaces.filter(w => w.output === root.monitorName).sort((a, b) => a.idx - b.idx)
                : Hyprland.workspaces

            Item {
                required property var modelData
                readonly property bool isFocused: Compositor.mango ? modelData.is_active
                    : root.onNiri ? modelData.is_active : modelData.focused

                visible: Compositor.mango || root.onNiri || modelData.monitor?.name === root.monitorName
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: label.implicitWidth + 6
                implicitHeight: label.implicitHeight

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: Compositor.mango ? String(parent.modelData.index)
                        : root.onNiri
                        ? (parent.modelData.name || String(parent.modelData.idx))
                        : parent.modelData.name
                    font.family: Theme.nerdFont
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: parent.isFocused ? Font.DemiBold : Font.Normal
                    color: parent.isFocused
                        ? (root.foreground.r < 0.5 ? "#315fa8" : Theme.blue)
                        : root.foreground
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (Compositor.mango)
                            Mango.view(root.monitorName, parent.modelData.index)
                        else if (root.onNiri)
                            Quickshell.execDetached(["bash", root.niriScript, "focus", parent.modelData.output, String(parent.modelData.idx)])
                        else
                            parent.modelData.activate()
                    }
                }
            }
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked:   mouse => mouse.accepted = false
        onPressed:   mouse => mouse.accepted = false
        onReleased:  mouse => mouse.accepted = false
    }
}
