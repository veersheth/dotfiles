pragma Singleton
import QtQuick

// Thin signal bus — any module calls FlashService.trigger() and
// the Flash scope picks it up via Connections without IPC overhead.
QtObject {
    signal requested(color: color, duration: int)

    function trigger(color, duration) {
        requested(color, duration ?? 300);
    }
}
