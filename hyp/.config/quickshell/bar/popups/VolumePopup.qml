import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    contentWidth:  Theme.listWidth + 2 * contentPadding
    contentHeight: col.implicitHeight + 2 * contentPadding

    readonly property var  sink:   Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false

    readonly property var audioSinks:   Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var audioStreams: Pipewire.nodes.values.filter(n => n.isStream)

    PwObjectTracker { objects: [...root.audioSinks, ...root.audioStreams] }

    signal escaped()
    onEscaped: close()

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.escaped()
    }

    // ── Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 0

        // ── Master volume ──────────────────────────────────────────────
        Text {
            Layout.bottomMargin: 12
            text: "Volume"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

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

            CommonSlider {
                Layout.fillWidth: true
                value:     root.volume
                maxValue:  1.5
                tickAt:    1.0
                fillColor: root.muted ? Qt.alpha(Theme.foreground, 0.28)
                         : root.volume > 1.0 ? Theme.yellow : Theme.blue
                onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
            }

            Text {
                text: `${Math.round(root.volume * 100)}%`
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium
                color: root.volume > 1.0 ? Theme.yellow : Qt.alpha(Theme.foreground, 0.70)
                Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // ── App streams ────────────────────────────────────────────────
        Rectangle {
            visible: root.audioStreams.length > 0
            Layout.fillWidth: true; Layout.topMargin: 16; Layout.bottomMargin: 14
            height: 1; color: Qt.alpha(Theme.foreground, 0.08)
        }

        Text {
            visible: root.audioStreams.length > 0
            Layout.bottomMargin: 10
            text: "Apps"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        CommonList {
            visible: root.audioStreams.length > 0
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: root.audioStreams

                ColumnLayout {
                    id: streamItem
                    required property var modelData

                    readonly property real  sVol:   modelData.audio?.volume ?? 0
                    readonly property bool  sMuted: modelData.audio?.muted  ?? false
                    readonly property string iconSrc: {
                        const n = streamItem.modelData.name?.toLowerCase() ?? ""
                        const p = Quickshell.iconPath(n, true)
                        return p !== "" ? p : Quickshell.iconPath(n)
                    }

                    Layout.fillWidth: true
                    spacing: 5

                    // Name row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        IconImage {
                            implicitSize: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: streamItem.iconSrc
                            visible: streamItem.iconSrc !== ""
                        }

                        Text {
                            visible: streamItem.iconSrc === ""
                            text: "󰓃"
                            font.family: Theme.nerdFont
                            font.pixelSize: 14
                            color: Qt.alpha(Theme.foreground, 0.45)
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: streamItem.modelData.description || streamItem.modelData.name
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Medium
                            color: streamItem.sMuted
                                ? Qt.alpha(Theme.foreground, 0.4)
                                : Theme.foreground
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Rectangle {
                            width: 26; height: 26; radius: width / 2
                            color: sMuteMo.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: streamItem.sMuted ? "󰝟" : "󰕾"
                                font.family: Theme.nerdFont
                                font.pixelSize: Theme.iconSize - 2
                                color: streamItem.sMuted
                                    ? Qt.alpha(Theme.foreground, 0.35)
                                    : Qt.alpha(Theme.foreground, 0.65)
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            MouseArea {
                                id: sMuteMo; anchors.fill: parent; hoverEnabled: true
                                onClicked: if (streamItem.modelData.audio)
                                    streamItem.modelData.audio.muted = !streamItem.sMuted
                            }
                        }
                    }

                    // Slider row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 24
                        spacing: 8

                        CommonSlider {
                            Layout.fillWidth: true
                            value:    streamItem.sVol
                            maxValue: 1.0
                            fillColor: streamItem.sMuted
                                ? Qt.alpha(Theme.foreground, 0.18)
                                : Theme.blue
                            onMoved: v => { if (streamItem.modelData.audio)
                                streamItem.modelData.audio.volume = v }
                        }

                        Text {
                            text: `${Math.round(streamItem.sVol * 100)}%`
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            color: Qt.alpha(Theme.foreground, 0.5)
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }

        // ── Output devices ─────────────────────────────────────────────
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

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(34, Math.min(sinkCol.implicitHeight + 4, 150))
            contentHeight: sinkCol.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds

            CommonList {
                id: sinkCol
                width: parent.width

                Repeater {
                    model: root.audioSinks

                    delegate: Rectangle {
                        id: sinkRow
                        required property var modelData
                        readonly property bool active: Pipewire.defaultAudioSink?.id === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 34; radius: Theme.itemRadius
                        color: active               ? Qt.alpha(Theme.blue, 0.18)
                             : sinkMo.containsMouse  ? Theme.hover
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
