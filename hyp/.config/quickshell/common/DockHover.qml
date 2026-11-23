pragma Singleton
import Quickshell
import QtQuick

// Tracks hover by source instead of a single depth counter. The reveal strip,
// card gaps, and individual icons can all keep the dock revealed at once, and
// moving between them cannot briefly look like the pointer left entirely.
Singleton {
    id: root
    property int edge: 0
    property int card: 0
    property int icons: 0
    readonly property bool active: root.edge > 0 || root.card > 0 || root.icons > 0

    function enter(source) {
        switch (source) {
        case "edge":  root.edge++;  break;
        case "card":  root.card++;  break;
        case "icons": root.icons++; break;
        default:      root.card++;  break;
        }
    }

    function leave(source) {
        switch (source) {
        case "edge":  root.edge  = Math.max(0, root.edge  - 1); break;
        case "card":  root.card  = Math.max(0, root.card  - 1); break;
        case "icons": root.icons = Math.max(0, root.icons - 1); break;
        default:      root.card  = Math.max(0, root.card  - 1); break;
        }
    }

    function reset() {
        root.edge = 0
        root.card = 0
        root.icons = 0
    }
}
