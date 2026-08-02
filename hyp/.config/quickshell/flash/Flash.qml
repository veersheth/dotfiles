import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.common

// Screen-edge flash alert — like a Raycast notification burst.
//
//   qs ipc call flash trigger              # white flash (default)
//   qs ipc call flash triggerWith "#a7b8dd" 350   # custom colour + duration
//
// Or call Flash.trigger() / Flash.triggerWith(color, ms) from anywhere in the shell.
Scope {
    id: root

    // ── Public API ─────────────────────────────────────────────────────
    property color flashColor:    "#ffffff"
    property int   flashDuration: 300
    property int   glowSize:      90    // px from each screen edge

    function trigger() {
        _flash(root.flashColor, root.flashDuration);
    }

    function triggerWith(color, duration) {
        _flash(color ?? "#ffffff", duration ?? root.flashDuration);
    }

    // ── Internal ───────────────────────────────────────────────────────
    property real _opacity: 0
    property bool _active:  false

    function _flash(color, duration) {
        root.flashColor    = color;
        root._active       = true;
        _fadeIn.duration   = Math.round(duration * 0.35);
        _fadeOut.duration  = Math.round(duration * 0.65);
        _fade.restart();
    }

    SequentialAnimation {
        id: _fade

        NumberAnimation {
            id:          _fadeIn
            target:      root; property: "_opacity"
            from: 0; to: 1
            easing.type: Easing.Linear
        }
        NumberAnimation {
            id:          _fadeOut
            target:      root; property: "_opacity"
            to: 0
            easing.type: Easing.Linear
        }
        ScriptAction { script: root._active = false }
    }

    // Internal signal bus (used by Osd and anything else in-process)
    Connections {
        target: FlashService
        function onRequested(color, duration) { root._flash(color, duration) }
    }

    // External IPC — qs ipc call flash trigger / triggerWith "#rrggbb" 500
    IpcHandler {
        target: "flash"
        function trigger(): void { root.trigger() }
        function triggerWith(color: string, duration: int): void {
            root.triggerWith(color, duration);
        }
    }

    // ── One fullscreen overlay per physical screen ─────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen:        modelData
            anchors.top:   true
            anchors.bottom: true
            anchors.left:  true
            anchors.right: true
            exclusiveZone: -1
            color:         "transparent"
            visible:       root._active
            mask:          Region {}   // fully click-through

            WlrLayershell.namespace: "quickshell:flash"
            WlrLayershell.layer:    WlrLayer.Overlay

            Item {
                anchors.fill: parent
                opacity:      root._opacity

                // Top edge
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: root.glowSize
                    color:  "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: root.flashColor }
                        GradientStop { position: 1.0; color: "transparent"   }
                    }
                }

                // Bottom edge
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: root.glowSize
                    color:  "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "transparent"   }
                        GradientStop { position: 1.0; color: root.flashColor }
                    }
                }

                // Left edge
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width:  root.glowSize
                    color:  "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.flashColor }
                        GradientStop { position: 1.0; color: "transparent"   }
                    }
                }

                // Right edge
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width:  root.glowSize
                    color:  "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent"   }
                        GradientStop { position: 1.0; color: root.flashColor }
                    }
                }
            }
        }
    }
}
