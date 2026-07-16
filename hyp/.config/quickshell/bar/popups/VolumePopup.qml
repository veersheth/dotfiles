import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    contentWidth:  300
    contentHeight: 280

    readonly property var  sink:   Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false

    // Hardware sinks only — exclude application streams
    readonly property var audioSinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)

    PwObjectTracker { objects: root.audioSinks }

    // ── Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 0

        Text {
            Layout.bottomMargin: 12
            text: "Volume"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        // ── Slider row ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Mute toggle
            Rectangle {
                width: 32; height: 32; radius: width / 2
                color: muteMo.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: root.muted          ? "󰝟"
                        : root.volume < 0.33  ? "󰕿"
                        : root.volume < 0.66  ? "󰖀"
                        : "󰕾"
                    font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize + 1
                    color: root.muted ? Qt.alpha(Theme.foreground, 0.4) : Theme.foreground
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea {
                    id: muteMo; anchors.fill: parent; hoverEnabled: true
                    onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.muted
                }
            }

            // Volume track (0 – 150%; 100% marker)
            Item {
                Layout.fillWidth: true
                height: 20

                Rectangle {
                    id: volTrack
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 4; radius: 2
                    color: Qt.alpha(Theme.foreground, 0.12)

                    // 100% tick
                    Rectangle {
                        x: parent.width * (1.0 / 1.5) - 1
                        width: 2; height: parent.height * 2.5
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 1
                        color: Qt.alpha(Theme.foreground, 0.28)
                    }

                    Rectangle {
                        width: Math.min(1, root.volume / 1.5) * parent.width
                        height: parent.height; radius: 2
                        color: root.muted        ? Qt.alpha(Theme.foreground, 0.28)
                             : root.volume > 1.0 ? Theme.yellow
                             : Theme.blue
                        Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        x: Math.max(0, Math.min(volTrack.width - width,
                            (root.volume / 1.5) * volTrack.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7; color: "white"; z: 1
                        scale: volArea.containsMouse || volArea.pressed ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    }

                    MouseArea {
                        id: volArea
                        anchors { fill: parent; margins: -8 }
                        hoverEnabled: true
                        function set(mx) {
                            if (!root.sink?.audio) return
                            root.sink.audio.volume = Math.max(0, Math.min(1.5, (mx / volTrack.width) * 1.5))
                        }
                        onPressed:         ev => set(ev.x)
                        onPositionChanged: ev => { if (pressed) set(ev.x) }
                    }
                }
            }

            // Percentage
            Text {
                text: `${Math.round(root.volume * 100)}%`
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium
                color: root.volume > 1.0 ? Theme.yellow : Qt.alpha(Theme.foreground, 0.70)
                Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // ── Divider ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 16; Layout.bottomMargin: 12
            height: 1; color: Qt.alpha(Theme.foreground, 0.08)
        }

        Text {
            Layout.bottomMargin: 6
            text: "Output"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        // ── Sink list ──────────────────────────────────────────────────
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentHeight: sinkCol.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: sinkCol
                width: parent.width; spacing: 2

                Repeater {
                    model: root.audioSinks

                    delegate: Rectangle {
                        id: sinkRow
                        required property var modelData
                        readonly property bool active: Pipewire.defaultAudioSink?.id === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 34; radius: Theme.itemRadius
                        color: active              ? Qt.alpha(Theme.blue, 0.18)
                             : sinkMo.containsMouse ? Theme.hover
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10

                            Text {
                                text: "󰄬"
                                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                                color: Theme.blue
                                opacity: sinkRow.active ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                Layout.preferredWidth: 14
                            }

                            Text {
                                Layout.fillWidth: true; elide: Text.ElideRight
                                text: modelData.description || modelData.name
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                                font.weight: sinkRow.active ? Font.DemiBold : Font.Medium
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: sinkMo; anchors.fill: parent; hoverEnabled: true
                            onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                        }
                    }
                }

                Text {
                    visible: root.audioSinks.length === 0
                    Layout.fillWidth: true; topPadding: 4; leftPadding: 4
                    text: "No output devices found"
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    color: Qt.alpha(Theme.foreground, 0.45)
                }
            }
        }
    }
}
