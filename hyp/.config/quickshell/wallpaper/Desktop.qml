import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.wallpaper

Scope {
    id: root

    property string wallpaper: ""

    onWallpaperChanged: WallpaperService.current = wallpaper
    Component.onCompleted: WallpaperService.current = wallpaper

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
                source:       root.wallpaper.length > 0 ? "file://" + root.wallpaper : ""
                fillMode:     Image.PreserveAspectCrop
                smooth:       true
                asynchronous: true
            }
        }
    }
}
