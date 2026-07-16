import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root

    contentWidth:  290
    contentHeight: col.implicitHeight + 44

    // ── System stats state ─────────────────────────────────────────────
    property real cpuUsage:    0
    property real memUsedMb:   0
    property real memTotalMb:  1
    property real swapUsedMb:  0
    property real swapTotalMb: 0
    property var  _cpuPrev:    null

    property int  cpuTempC:   -1   // -1 = unavailable
    property int  gpuTempC:   -1
    property int  fanRpm:     -1   // highest fan if multiple

    function fmtMb(mb) {
        return mb >= 1024 ? `${(mb / 1024).toFixed(1)} GB` : `${mb} MB`
    }

    // CPU usage: delta between two /proc/stat samples
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).slice(1).map(Number)
                if (parts.length < 4) return
                const idle  = parts[3] + (parts[4] ?? 0)
                const total = parts.reduce((a, b) => a + b, 0)
                if (root._cpuPrev !== null) {
                    const dIdle  = idle  - root._cpuPrev[0]
                    const dTotal = total - root._cpuPrev[1]
                    root.cpuUsage = dTotal > 0
                        ? Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)))
                        : 0
                }
                root._cpuPrev = [idle, total]
            }
        }
    }

    // Memory
    Process {
        id: memProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, avail = 0, swapTotal = 0, swapFree = 0
                for (const line of text.trim().split("\n")) {
                    const m = line.match(/^(\w+):\s+(\d+)/)
                    if (!m) continue
                    const v = parseInt(m[2])
                    if (m[1] === "MemTotal")     total     = v
                    if (m[1] === "MemAvailable") avail     = v
                    if (m[1] === "SwapTotal")    swapTotal = v
                    if (m[1] === "SwapFree")     swapFree  = v
                }
                root.memTotalMb  = Math.max(1, Math.round(total / 1024))
                root.memUsedMb   = Math.round((total - avail)   / 1024)
                root.swapTotalMb = Math.round(swapTotal         / 1024)
                root.swapUsedMb  = Math.round((swapTotal - swapFree) / 1024)
            }
        }
    }

    // Temperature + fans: walk hwmon sysfs — pure memory reads, negligible cost
    Process {
        id: hwProc
        command: ["sh", "-c", [
            "for d in /sys/class/hwmon/hwmon*; do",
            "  n=$(cat \"$d/name\" 2>/dev/null || echo '')",
            "  case $n in",
            "    coretemp|k10temp|zenpower|zenergy)",
            "      t=$(cat \"$d/temp1_input\" 2>/dev/null) && echo \"cpu:$t\" ;;",
            "    amdgpu|radeon|nvidia|nouveau)",
            "      t=$(cat \"$d/temp1_input\" 2>/dev/null) && echo \"gpu:$t\" ;;",
            "  esac",
            "  for f in \"$d\"/fan*_input; do",
            "    [ -f \"$f\" ] && v=$(cat \"$f\") && [ \"$v\" -gt 0 ] 2>/dev/null && echo \"fan:$v\"",
            "  done",
            "done"
        ].join(" ")]
        stdout: StdioCollector {
            onStreamFinished: {
                let cpuT = -1, gpuT = -1, maxFan = -1
                for (const line of text.trim().split("\n")) {
                    const [key, val] = line.split(":")
                    const n = parseInt(val)
                    if (isNaN(n)) continue
                    if (key === "cpu") cpuT  = Math.round(n / 1000)
                    if (key === "gpu") gpuT  = Math.round(n / 1000)
                    if (key === "fan") maxFan = Math.max(maxFan, n)
                }
                root.cpuTempC = cpuT
                root.gpuTempC = gpuT
                root.fanRpm   = maxFan
            }
        }
    }

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.shown
        onTriggered: { cpuProc.running = true; memProc.running = true; hwProc.running = true }
    }

    onShownChanged: { if (!shown) root._cpuPrev = null }

    // ── Stat bar ───────────────────────────────────────────────────────
    component StatBar: RowLayout {
        id: sb
        property string label:     ""
        property real   frac:      0
        property string valueText: ""
        property color  barColor:  Theme.blue

        Layout.fillWidth: true
        spacing: 0

        Text {
            text: sb.label
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            color: Qt.alpha(Theme.foreground, 0.65)
            Layout.preferredWidth: 42
        }

        Rectangle {
            Layout.fillWidth: true
            height: 5; radius: height / 2
            color: Qt.alpha(Theme.foreground, 0.10)
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, sb.frac))
                height: parent.height; radius: parent.radius
                color: sb.barColor
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: 400 } }
            }
        }

        Text {
            text: sb.valueText
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            color: Qt.alpha(Theme.foreground, 0.55)
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 58
            Layout.leftMargin: 8
        }
    }

    // ── Profile row ────────────────────────────────────────────────────
    component ProfileRow: Rectangle {
        id: profileRow
        required property int    profile
        required property string icon
        required property string label
        readonly property bool   active: PowerProfiles.profile === profile

        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.itemRadius
        color: active ? Qt.alpha(Theme.blue, 0.25)
             : rowMo.containsMouse ? Theme.hover
             : "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 10
            Text {
                text: profileRow.icon
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize
                color: profileRow.active ? Theme.blue : Theme.foreground
            }
            Text {
                Layout.fillWidth: true
                text: profileRow.label
                font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium
                color: Theme.foreground
            }
            Text {
                visible: profileRow.active
                text: "󰄬"
                font.family: Theme.nerdFont; font.pixelSize: Theme.iconSize - 2
                color: Theme.blue
            }
        }

        MouseArea {
            id: rowMo; anchors.fill: parent; hoverEnabled: true
            onClicked: { PowerProfiles.profile = profileRow.profile; root.close() }
        }
    }

    // ── Layout ─────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: root.contentWidth - 40
        spacing: 6

        Text {
            Layout.leftMargin: 4; Layout.bottomMargin: 2
            text: "Power Profile"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        ProfileRow { profile: PowerProfile.PowerSaver;   icon: "󰌪"; label: "Power Saver" }
        ProfileRow { profile: PowerProfile.Balanced;     icon: "󰾅"; label: "Balanced" }
        ProfileRow {
            profile: PowerProfile.Performance; icon: "󰓅"; label: "Performance"
            visible: PowerProfiles.hasPerformanceProfile
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 12; Layout.bottomMargin: 12
            height: 1
            color: Qt.alpha(Theme.foreground, 0.08)
        }

        StatBar {
            label: "CPU"
            frac:  root.cpuUsage / 100
            valueText: `${root.cpuUsage}%`
            barColor: root.cpuUsage > 80 ? Theme.red
                    : root.cpuUsage > 50 ? "#e8a44a"
                    : Theme.green
        }

        StatBar {
            visible: root.cpuTempC >= 0
            label: "Temp"
            frac:  Math.min(1, root.cpuTempC / 100)
            valueText: `${root.cpuTempC}°C`
            barColor: root.cpuTempC > 85 ? Theme.red
                    : root.cpuTempC > 65 ? "#e8a44a"
                    : Theme.green
        }

        StatBar {
            visible: root.gpuTempC >= 0
            label: "GPU"
            frac:  Math.min(1, root.gpuTempC / 100)
            valueText: `${root.gpuTempC}°C`
            barColor: root.gpuTempC > 85 ? Theme.red
                    : root.gpuTempC > 65 ? "#e8a44a"
                    : Theme.green
        }

        StatBar {
            label: "RAM"
            frac:  root.memTotalMb > 0 ? root.memUsedMb / root.memTotalMb : 0
            valueText: root.fmtMb(root.memUsedMb)
            barColor: Theme.blue
        }

        StatBar {
            visible: root.swapTotalMb > 0
            label:   "Swap"
            frac:    root.swapTotalMb > 0 ? root.swapUsedMb / root.swapTotalMb : 0
            valueText: root.fmtMb(root.swapUsedMb)
            barColor: Qt.alpha(Theme.foreground, 0.45)
        }

        StatBar {
            visible: root.fanRpm >= 0
            label: "Fan"
            frac:  Math.min(1, root.fanRpm / 4000)
            valueText: `${root.fanRpm} rpm`
            barColor: Theme.blue
        }

        // Battery time — centred, dim, at the very bottom
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28

            readonly property var  bat:      UPower.displayDevice
            readonly property bool charging: bat !== null &&
                (bat.state === UPowerDeviceState.Charging ||
                 bat.state === UPowerDeviceState.FullyCharged ||
                 bat.state === UPowerDeviceState.PendingCharge)
            readonly property int  secs: charging ? (bat?.timeToFull ?? 0) : (bat?.timeToEmpty ?? 0)

            text: {
                if (bat?.state === UPowerDeviceState.FullyCharged) return "Fully charged"
                const m = Math.round(secs / 60)
                const fmt = m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`
                if (secs <= 0) return charging ? "Charging" : "On battery"
                return charging ? `${fmt} until full` : `${fmt} remaining`
            }

            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            color: Qt.alpha(Theme.foreground, 0.68)
        }
    }
}
