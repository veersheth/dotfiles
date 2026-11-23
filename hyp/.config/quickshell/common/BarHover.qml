pragma Singleton
import Quickshell
import QtQuick

// Tracks whether the pointer is over any bar module, so a peeked auto-hide
// bar knows when it is safe to slide away again.
Singleton {
    id: root
    property int depth: 0
    readonly property bool active: depth > 0

    function enter() { depth++ }
    function leave() { depth = Math.max(0, depth - 1) }
    function reset() { depth = 0 }
}
