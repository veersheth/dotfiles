pragma Singleton
import QtQuick

// ─── Theme ────────────────────────────────────────────────────────────────
// All colors/fonts/sizes live here. Edit this file to restyle everything.
// NOTE: QML colors are #AARRGGBB (alpha first), so web-style #RRGGBBAA
// values are written with the alpha moved to the front.

QtObject {
    // Colors
    readonly property color background: "#DD000000"   // #00000088
    readonly property color surface:    "#FF101010"   // #262626ff
    readonly property color border:     "#66ffffff"   // #ffffff22
    readonly property color barBorder:  "#00ffffff"   // bottom border of the status bar
    readonly property color foreground: "#ffffffff"   // #ffffffff
    readonly property color onAccent:   "#ff1a1a1a"   // dark text on accent fills
    readonly property color hover:      "#22ffffff"   // subtle hover wash
    readonly property color hoverStrong:"#33ffffff"  // stronger hover / selection
    readonly property color blue:       "#a7b8dd"
    readonly property color red:        "#d84b4b"
    readonly property color green:      "#95dd8d"
    readonly property color yellow:     "#d2d270"

    // Type
    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property string nerdFont: "JetBrainsMono Nerd Font"
    readonly property int    fontSize: 13
    readonly property int    iconSize: 16

    // Metrics
    readonly property int barHeight:    30
    readonly property int radius:       0    // large pill containers, dock card
    readonly property int popupRadius:  12    // popup cards, floating labels
    readonly property int itemRadius:   10    // list rows, interactive hover tiles
    readonly property int smallRadius:  8     // small chips, action buttons, cell:
    readonly property int borderWidth:  1
    readonly property int pillHeight:   28    // window class / clock pills
    readonly property int moduleSpacing: 2
    readonly property int iconSlot:     iconSize + 20  // 34px — standard single-icon bar slot

    // Animation
    readonly property int animDuration: 150

    // Shared component widths —  popups set contentWidth = {list,slider}Width + 2 * contentPadding
    readonly property int listWidth:   300
    readonly property int sliderWidth: 300
}
