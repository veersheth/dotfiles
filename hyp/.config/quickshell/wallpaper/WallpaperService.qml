pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool   pickerShown: false
    property string current:     ""
    property var    wallpapers:  []

    function togglePicker() { pickerShown = !pickerShown; }

    function apply(p) {
        current = p;
        // persist across restarts
        writeConf.running = false;
        writeConf.running = true;
    }

    // Scan wallpapers directory
    Process {
        id: scan
        running: true
        command: ["sh", "-c",
            "ls -1 \"$HOME/wallpapers/\" 2>/dev/null" +
            " | grep -iE '\\.(jpg|jpeg|png|webp)$'" +
            " | sed \"s|^|$HOME/wallpapers/|\"" +
            " | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                    .map(l => l.trim()).filter(l => l.length > 0);
                root.wallpapers = lines;
            }
        }
        stderr: SplitParser {
            onRead: line => console.log("[wallpaper scan err]", line)
        }
    }

    // Load saved wallpaper on start
    Process {
        running: true
        command: ["sh", "-c", "cat \"$HOME/.config/quickshell/wallpaper.conf\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p.length > 0) root.current = p;
            }
        }
    }

    // Save wallpaper on change
    Process {
        id: writeConf
        command: ["sh", "-c",
            "echo " + JSON.stringify(root.current) +
            " > \"$HOME/.config/quickshell/wallpaper.conf\""]
    }
}
