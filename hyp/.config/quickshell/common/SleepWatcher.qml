pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Watches systemd-logind's PrepareForSleep D-Bus signal.
// Emits woke() when the system resumes from suspend — use this to
// force clock widgets to re-sync; SystemClock's internal QTimer
// can freeze across a sleep/wake cycle.
Singleton {
    id: root

    signal woke()

    Process {
        running: true
        command: ["dbus-monitor", "--system",
            "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: line => {
                // PrepareForSleep(true)  = going to sleep
                // PrepareForSleep(false) = waking up
                if (line.trim() === "boolean false") root.woke();
            }
        }
    }
}
