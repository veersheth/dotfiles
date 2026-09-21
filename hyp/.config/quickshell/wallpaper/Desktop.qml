import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.components
import qs.wallpaper

Scope {
    id: root

    // fallback from shell.qml, used until a wallpaper is picked
    property string wallpaper: ""
    // user pick, persisted across restarts; click the desktop to change
    property string chosen: ""
    readonly property string effective: chosen !== "" ? chosen : wallpaper

    onEffectiveChanged: WallpaperService.current = effective
    Component.onCompleted: WallpaperService.current = effective

    FileView {
        id: store
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/wallpaper.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            const p = text().trim();
            if (p !== "") root.chosen = p;
        }
    }

    // ── Image picker ──────────────────────────────────────────────────────
    // XDG FileChooser portal — GTK_USE_PORTAL=1 makes zenity delegate to the
    // portal backend, giving the native system file picker instead of its own widget.
    Process {
        id: pickerProc
        environment: ({ GTK_USE_PORTAL: "1" })
        command: ["zenity", "--file-selection",
                  "--title=Choose wallpaper",
                  "--file-filter=Images | *.jpg *.jpeg *.png *.webp *.bmp *.avif",
                  "--filename=" + (!WallpaperService.isColor && root.effective !== ""
                      ? root.effective.substring(0, root.effective.lastIndexOf("/")) + "/"
                      : Quickshell.env("HOME") + "/Pictures/")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out === "") return;
                root.chosen = out;
                store.setText(out);
            }
        }
    }

    Connections {
        target: BarState
        function onWallpaperPickerRequested() { pickerProc.running = true }
    }

    // ── Color picker ──────────────────────────────────────────────────────
    // zenity --color-selection outputs rgb(r,g,b) — we convert to #rrggbb
    // and store it prefixed with "color:" so we can distinguish from a path.
    Process {
        id: colorPickerProc
        command: (function() {
            const args = ["zenity", "--color-selection",
                          "--title=Choose background color",
                          "--show-palette"]
            // seed with current color if already in color mode
            if (WallpaperService.isColor)
                args.push("--color=" + WallpaperService.colorValue)
            return args
        })()
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out === "") return;
                // rgb(r,g,b) or rgba(r,g,b,a) → #rrggbb
                const m = out.match(/(\d+),\s*(\d+),\s*(\d+)/);
                if (!m) return;
                const hex = "#" + [m[1], m[2], m[3]].map(
                    v => parseInt(v).toString(16).padStart(2, "0")).join("");
                const stored = "color:" + hex;
                root.chosen = stored;
                store.setText(stored);
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            // Background layer — the wallpaper or solid color
            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: -1
                // Window background: solid color when in color mode,
                // black fallback while image loads (or when no wallpaper set)
                color: WallpaperService.isColor ? WallpaperService.colorValue : "black"
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "quickshell:wallpaper"

                Image {
                    anchors.fill: parent
                    visible: !WallpaperService.isColor
                    source: (!WallpaperService.isColor && root.effective.length > 0)
                            ? "file://" + root.effective : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                }

                // right click → context menu leaking from the bar above the cursor
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        const half = desktopMenu.implicitWidth / 2 + 8;
                        menuAnchor.x = Math.max(half, Math.min(mouse.x, width - half));
                        desktopMenu.toggle();
                    }
                }

                // invisible nub the menu morphs out of, moved to the click x
                Item {
                    id: menuAnchor
                    y: 0
                    width: 1
                    height: 1
                }
            }

            // Desktop context menu — same leak card as every bar popup
            BarPopup {
                id: desktopMenu
                anchorItem: menuAnchor
                contentWidth: 246
                contentHeight: menuCol.implicitHeight + 32

                Column {
                    id: menuCol
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                    spacing: 4

                    Rectangle {
                        width: parent.width; height: 34; radius: 9
                        color: wallMo.containsMouse ? Theme.hover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 9
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰸉"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Theme.foreground }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Change background…"; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; color: Theme.foreground }
                        }
                        MouseArea { id: wallMo; anchors.fill: parent; hoverEnabled: true; onClicked: { desktopMenu.close(); pickerProc.running = true } }
                    }

                    Rectangle {
                        width: parent.width; height: 34; radius: 9
                        color: colorMo.containsMouse ? Theme.hover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 9
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰏘"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Theme.foreground }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Set solid color…"; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; color: Theme.foreground }
                        }
                        MouseArea { id: colorMo; anchors.fill: parent; hoverEnabled: true; onClicked: { desktopMenu.close(); colorPickerProc.running = true } }
                    }

                    Rectangle {
                        width: parent.width; height: 34; radius: 9
                        color: barPosMo.containsMouse ? Theme.hover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 9
                            Text { anchors.verticalCenter: parent.verticalCenter; text: BarState.barBottom ? "󰹙" : "󰹘"; font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize; color: Theme.foreground }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: BarState.barBottom ? "Move bar to top" : "Move bar to bottom"; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; color: Theme.foreground }
                        }
                        MouseArea { id: barPosMo; anchors.fill: parent; hoverEnabled: true; onClicked: { desktopMenu.close(); BarState.setBottom(!BarState.barBottom) } }
                    }
                }
            }
        }
    }
}
