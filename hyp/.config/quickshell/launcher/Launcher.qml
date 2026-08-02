import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import qs.common
import qs.wallpaper

Scope {
    id: root

    property bool shown: false
    property var  allApps: []

    function toggle() { shown = !shown }
    function open()   { shown = true }
    function close()  { shown = false }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open():   void { root.open() }
        function close():  void { root.close() }
    }

    Process {
        running: true
        command: ["python3", "-c",
            "import glob,configparser,re,os,json\n" +
            "dirs=os.environ.get('XDG_DATA_DIRS','').split(':')+[os.path.expanduser('~/.local/share')]\n" +
            "seen=set();apps=[]\n" +
            "for d in dirs:\n" +
            " for f in sorted(glob.glob(os.path.join(d,'applications','*.desktop'))):\n" +
            "  p=configparser.RawConfigParser()\n" +
            "  try: p.read(f)\n" +
            "  except: continue\n" +
            "  s='Desktop Entry'\n" +
            "  if not p.has_section(s): continue\n" +
            "  try:\n" +
            "   if p.get(s,'Type')!='Application': continue\n" +
            "  except: continue\n" +
            "  if p.getboolean(s,'NoDisplay',fallback=False): continue\n" +
            "  if p.getboolean(s,'Hidden',fallback=False): continue\n" +
            "  name=p.get(s,'Name',fallback='');exec_=p.get(s,'Exec',fallback='');icon=p.get(s,'Icon',fallback='')\n" +
            "  if name and exec_ and name not in seen:\n" +
            "   seen.add(name)\n" +
            "   exec_=re.sub(r' ?%[a-zA-Z]','',exec_).strip()\n" +
            "   terminal=p.getboolean(s,'Terminal',fallback=False)\n" +
            "   if terminal: exec_='ghostty -- '+exec_\n" +
            "   apps.append({'name':name,'exec':exec_,'icon':icon})\n" +
            "apps.sort(key=lambda x:x['name'].lower())\n" +
            "print(json.dumps(apps))\n"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.allApps = JSON.parse(text); grid.updateFilter() }
                catch(e) { console.warn("Launcher: failed to parse apps:", e) }
            }
        }
    }

    PanelWindow {
        id: win

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"
        visible: false

        WlrLayershell.namespace: "quickshell:launcher"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        readonly property int cols:  6
        readonly property int cellW: 200
        readonly property int cellH: 180
        readonly property int gridW: cols * cellW   // 1200px — centred, 360px aside on 1920

        property bool shown: root.shown
        onShownChanged: {
            if (shown) {
                exitAnim.stop()
                visible = true
                content.opacity = 0
                gridArea.scale   = 0.9
                gridArea.opacity = 0
                enterAnim.restart()
                searchField.text = ""
                searchField.forceActiveFocus()
                grid.positionViewAtBeginning()
            } else {
                enterAnim.stop()
                exitAnim.restart()
            }
        }

        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: content;  property: "opacity"; from: 0;   to: 1;   duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: gridArea; property: "scale";   from: 0.9; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: gridArea; property: "opacity"; from: 0;   to: 1;   duration: 200; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            id: exitAnim
            ParallelAnimation {
                NumberAnimation { target: content;  property: "opacity"; to: 0;    duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { target: gridArea; property: "scale";   to: 0.93; duration: 160; easing.type: Easing.InCubic }
            }
            ScriptAction { script: win.visible = false }
        }

        // ── Background ────────────────────────────────────────────────
        Image {
            id: wall
            anchors.fill: parent
            source: WallpaperService.current.length > 0 ? "file://" + WallpaperService.current : ""
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            blurMax: 48
            blur: 0.8
        }
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.5 }

        Item {
            id: content
            anchors.fill: parent
            opacity: 0

            MouseArea { anchors.fill: parent; onClicked: root.close() }

            // ── Search bar — appears when typing ─────────────────────
            Item {
                id: searchRow
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 48
                }
                width: win.gridW
                height: 46
                opacity: searchField.text !== "" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: Theme.borderWidth
                    border.color: Qt.alpha(Theme.foreground, 0.22)

                    TextInput {
                        id: searchField
                        anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.font; font.pixelSize: Theme.fontSize
                        color: Theme.foreground
                        clip: true

                        onTextChanged: grid.updateFilter()

                        Keys.onEscapePressed: {
                            if (text !== "") text = ""
                            else root.close()
                        }
                        Keys.onReturnPressed: {
                            if (grid._data.length > 0) {
                                Quickshell.execDetached(["sh", "-c", grid._data[0].exec])
                                root.close()
                            }
                        }
                    }
                }
            }

            // ── App grid ─────────────────────────────────────────────
            Item {
                id: gridArea
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: searchField.text !== "" ? 114 : 48
                }
                width: win.gridW

                Behavior on anchors.topMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                GridView {
                    id: grid
                    anchors { fill: parent; topMargin: 16; bottomMargin: 48 }
                    cellWidth:  win.cellW
                    cellHeight: win.cellH
                    clip: true
                    flickDeceleration: 300
                    maximumFlickVelocity: 6000
                    pixelAligned: false

                    property var _data: []
                    model: _data.length

                    function updateFilter() {
                        const q = searchField.text.toLowerCase()
                        _data = q === ""
                            ? root.allApps
                            : root.allApps.filter(a =>
                                a.name.toLowerCase().includes(q) ||
                                a.exec.toLowerCase().includes(q))
                        positionViewAtBeginning()
                    }

                    Connections {
                        target: root
                        function onAllAppsChanged() { grid.updateFilter() }
                    }

                    delegate: Item {
                        id: cell
                        required property int index

                        readonly property var    app:  grid._data[index]
                        readonly property string iSrc: Quickshell.iconPath(app?.icon ?? "", true)

                        width: win.cellW; height: win.cellH

                        Rectangle {
                            anchors { fill: parent; margins: 18 }
                            radius: Theme.popupRadius
                            color: Qt.rgba(1, 1, 1, 0.08)
                            opacity: cellMo.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Item {
                                width: 80; height: 80
                                anchors.horizontalCenter: parent.horizontalCenter
                                scale: cellMo.pressed ? 0.86 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 80
                                    source: cell.iSrc
                                    visible: cell.iSrc !== ""
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 80; height: 80; radius: 18
                                    visible: cell.iSrc === ""
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    border.width: Theme.borderWidth
                                    border.color: Qt.alpha(Theme.foreground, 0.2)
                                    Text {
                                        anchors.centerIn: parent
                                        text: (cell.app?.name ?? "?").charAt(0).toUpperCase()
                                        font.family: Theme.font; font.pixelSize: 32
                                        font.weight: Font.DemiBold
                                        color: Qt.alpha(Theme.foreground, 0.7)
                                    }
                                }
                            }

                            Text {
                                width: win.cellW - 32
                                anchors.horizontalCenter: parent.horizontalCenter
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: cell.app?.name ?? ""
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.Medium
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: cellMo
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["sh", "-c", cell.app.exec])
                                root.close()
                            }
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.shown
            onActivated: root.close()
        }
    }
}
