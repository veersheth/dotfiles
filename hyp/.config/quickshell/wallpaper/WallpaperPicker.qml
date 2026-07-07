import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.wallpaper

// Grid of wallpaper thumbnails that leaks from the top of the screen.
// Opened by right-clicking the desktop (Desktop.qml).
PanelWindow {
    id: win

    readonly property bool shown: WallpaperService.pickerShown

    readonly property int columns: 4
    readonly property int cellW:   200
    readonly property int cellH:   134
    readonly property int pad:      16
    readonly property real gridW:  columns * cellW + pad * 2
    readonly property real gridH:  Math.round((screen?.height ?? 1080) * 0.72)

    property real progress: 0

    anchors.top:   true
    exclusiveZone: 0
    implicitWidth:  gridW + card.flare * 2
    implicitHeight: gridH
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "quickshell:wallpaperPicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onShownChanged: {
        if (shown) {
            exitAnim.stop();
            visible = true;
            enterAnim.restart();
        } else {
            enterAnim.stop();
            exitAnim.restart();
        }
    }

    HyprlandFocusGrab {
        windows: [win]
        active:  win.shown
        onCleared: WallpaperService.pickerShown = false
    }

    NumberAnimation {
        id: enterAnim
        target: win; property: "progress"
        to: 1; duration: 400
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }
    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: win; property: "progress"
            to: 0; duration: 180; easing.type: Easing.InCubic
        }
        ScriptAction { script: win.visible = false }
    }

    LeakCard {
        id: card
        anchors.fill: parent
        contentWidth:  win.gridW
        contentHeight: win.gridH
        progress:      win.progress
        startWidth:    160
        overlap:       0

        GridView {
            id: grid
            anchors.fill:    parent
            anchors.margins: win.pad
            clip:            true

            cellWidth:  win.cellW
            cellHeight: win.cellH
            model: WallpaperService.wallpapers

            delegate: Item {
                required property string modelData
                required property int    index

                width:  win.cellW
                height: win.cellH

                readonly property bool active: WallpaperService.current === modelData

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: 6
                    radius:          10
                    color:           "transparent"
                    border.width:    active ? 2 : 1
                    border.color:    active ? Theme.blue : Theme.border

                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: parent.border.width
                        radius:          parent.radius - parent.border.width
                        clip:            true
                        color:           "#111"

                        Image {
                            anchors.fill: parent
                            source:       "file://" + modelData
                            fillMode:     Image.PreserveAspectCrop
                            smooth:       true
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color:        thumbMouse.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                        }
                    }

                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            WallpaperService.apply(modelData);
                            WallpaperService.pickerShown = false;
                        }
                    }
                }
            }
        }
    }
}
