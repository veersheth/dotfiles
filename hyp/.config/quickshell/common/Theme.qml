pragma Singleton
import QtQuick

// ─── Theme ────────────────────────────────────────────────────────────────
// All colors/fonts/sizes live here. Edit this file to restyle everything.
// NOTE: QML colors are #AARRGGBB (alpha first), so web-style #RRGGBBAA
// values are written with the alpha moved to the front.

QtObject {
    // Colors
    readonly property color background: "#EE232323"   // #00000088
    readonly property color surface:    "#ff262626"   // #262626ff
    readonly property color border:     "#66ffffff"   // #ffffff22
    readonly property color barBorder:  "#55ffffff"   // bottom border of the status bar
    readonly property color foreground: "#ffffffff"   // #ffffffff
    readonly property color onAccent:   "#ff1a1a1a"   // dark text on accent fills
    readonly property color hover:      "#22ffffff"   // subtle hover wash
    readonly property color hoverStrong:"#33ffffff"  // stronger hover / selection
    readonly property color blue:       "#a7b8dd"
    readonly property color red:        "#d84b4b"
    readonly property color green:      "#95dd8d"
    readonly property color yellow:     "#d2d270"

    // Type
    readonly property string font:     "Inter"
    readonly property string nerdFont: "JetBrainsMono Nerd Font"
    readonly property int    fontSize: 14
    readonly property int    iconSize: 15

    // Metrics
    readonly property int barHeight:    34
    readonly property int radius:       20    // pill radius + screen "melt" corner radius
    readonly property int borderWidth:  1
    readonly property int pillHeight:   28    // window class / clock pills
    readonly property int moduleSpacing: 0
    readonly property int popupRadius:  26

    // Animation
    readonly property int animDuration: 200

    // Dock
    readonly property int   dockHideDelay:  600           // grace period before auto-hide (ms)
    readonly property int   dockPadding:    14            // space between icons and card edge
    // Alpha must stay above Hyprland's ignore_alpha (0.4) or blur won't apply
    readonly property color dockBackground: "#88000000"
}
