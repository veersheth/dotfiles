import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.wallpaper

Scope {
    // Background layer — wallpaper image, one per screen
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            color: "black"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"

            Image {
                anchors.fill: parent
                source:       WallpaperService.current.length > 0
                                  ? "file://" + WallpaperService.current : ""
                fillMode:     Image.PreserveAspectCrop
                smooth:       true
                asynchronous: true
            }
        }
    }

    // Bottom layer — catches right-click to open picker
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:desktop"

            MouseArea {
                anchors.fill:    parent
                acceptedButtons: Qt.RightButton
                onClicked:       WallpaperService.togglePicker()
            }
        }
    }
}
