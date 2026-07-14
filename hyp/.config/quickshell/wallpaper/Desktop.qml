import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Dialogs
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

    // Native GTK picker via zenity when installed; otherwise falls back
    // to the Qt dialog in pickerWin below.
    Process {
        id: zenityProc
        command: ["sh", "-c",
            'if command -v zenity >/dev/null 2>&1; then ' +
            'exec zenity --file-selection --title="Choose wallpaper" ' +
            '--file-filter="Images | *.jpg *.jpeg *.png *.webp *.bmp *.avif" ' +
            '--file-filter="All files | *" ' +
            '--filename="$START_DIR/"; ' +
            'else echo __NOZENITY__; fi']
        environment: ({ START_DIR: root.effective.substring(0, root.effective.lastIndexOf("/")) })
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out === "__NOZENITY__") { pickerWin.visible = true; return; }
                if (out === "") return;   // cancelled
                root.chosen = out;
                store.setText(out);
            }
        }
    }

    // Qt's file dialog needs a real toplevel to live in — layer-shell
    // surfaces don't qualify — so the picker borrows a floating window
    // that only exists while choosing.
    FloatingWindow {
        id: pickerWin
        visible: false
        title: "Choose wallpaper"
        implicitWidth: 760
        implicitHeight: 520
        color: Theme.surface

        onVisibleChanged: if (visible) Qt.callLater(() => picker.open())

        Item {
            anchors.fill: parent

            FileDialog {
                id: picker
                title: "Choose wallpaper"
                nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp *.avif)"]
                currentFolder: "file://" + root.effective.substring(0, root.effective.lastIndexOf("/"))
                onAccepted: {
                    const p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
                    root.chosen = p;
                    store.setText(p);
                    pickerWin.visible = false;
                }
                onRejected: pickerWin.visible = false
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            // Background layer — the wallpaper itself
            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: -1
                color: "black"
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "quickshell:wallpaper"

                Image {
                    anchors.fill: parent
                    source: root.effective.length > 0 ? "file://" + root.effective : ""
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
                contentWidth: entry.width + 20
                contentHeight: entry.height + 20

                Rectangle {
                    id: entry
                    anchors.centerIn: parent
                    width: 210
                    height: 34
                    radius: 9
                    color: entryMouse.containsMouse ? Theme.hover : "transparent"

                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 9

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰸉"
                            font.family: Theme.nerdFont
                            font.pixelSize: Theme.iconSize
                            color: Theme.foreground
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Change background…"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Medium
                            color: Theme.foreground
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            desktopMenu.close();
                            zenityProc.running = true;
                        }
                    }
                }
            }
        }
    }
}
