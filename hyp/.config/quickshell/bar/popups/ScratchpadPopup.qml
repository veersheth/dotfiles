import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.common
import qs.components

// Pull-down scratchpad — click an empty stretch of the bar to toggle it,
// Esc or another bar click to close; clicking elsewhere leaves it open.
// Notes autosave to ~/.local/state/quickshell/scratchpad.txt. Files and
// images dragged in land on a shelf strip: click to open, drag out to any
// app, right-click to remove.
BarPopup {
    id: root

    property bool loadedOk: false
    property bool shelfLoaded: false
    property var shelf: []   // array of URL strings

    dismissOnFocusLoss: false

    contentWidth: 460
    contentHeight: 340 + (shelf.length > 0 ? 88 : 0)

    onShownChanged: {
        if (shown) edit.forceActiveFocus();
        else if (loadedOk) file.setText(edit.text);   // flush on close
    }

    function addUrl(u) {
        if (!u || shelf.includes(u)) return;
        shelf = [...shelf, u];
        if (shelfLoaded) shelfFile.setText(JSON.stringify(shelf));
    }
    function removeUrl(u) {
        shelf = shelf.filter(x => x !== u);
        if (shelfLoaded) shelfFile.setText(JSON.stringify(shelf));
    }
    function isImage(u) { return /\.(png|jpe?g|webp|gif|svg|bmp|avif)$/i.test(u); }

    FileView {
        id: file
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/scratchpad.txt`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            edit.text = text();
            root.loadedOk = true;
        }
        onLoadFailed: root.loadedOk = true
    }
    FileView {
        id: shelfFile
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/scratchpad-shelf.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try { root.shelf = JSON.parse(text()); } catch (e) {}
            root.shelfLoaded = true;
        }
        onLoadFailed: root.shelfLoaded = true
    }

    Timer {
        id: saveDebounce
        interval: 800
        onTriggered: file.setText(edit.text)
    }

    // ── Notes ──────────────────────────────────────────────────────────
    Flickable {
        id: flick
        anchors {
            fill: parent; margins: 20
            bottomMargin: 20 + (root.shelf.length > 0 ? 88 : 0)
        }
        contentHeight: edit.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: edit
            width: flick.width
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            selectionColor: Qt.alpha(Theme.blue, 0.4)

            onTextChanged: if (root.loadedOk) saveDebounce.restart()
            Keys.onEscapePressed: root.close()

            // readline-style ctrl-w: delete back through spaces, then the word
            Keys.onPressed: event => {
                if (event.key === Qt.Key_W && event.modifiers & Qt.ControlModifier) {
                    const pos = cursorPosition;
                    let i = pos;
                    while (i > 0 && /\s/.test(text.charAt(i - 1))) i--;
                    while (i > 0 && !/\s/.test(text.charAt(i - 1))) i--;
                    remove(i, pos);
                    event.accepted = true;
                }
            }

            // keep the cursor in view while typing
            onCursorRectangleChanged: {
                const r = cursorRectangle;
                if (r.y < flick.contentY)
                    flick.contentY = r.y;
                else if (r.y + r.height > flick.contentY + flick.height)
                    flick.contentY = r.y + r.height - flick.height;
            }
        }
    }

    Text {
        anchors { top: parent.top; left: parent.left; margins: 20 }
        visible: edit.text === ""
        text: "Scratchpad… (drop files here)"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Qt.alpha(Theme.foreground, 0.35)
    }

    // ── Shelf: dropped files ───────────────────────────────────────────
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: shelfList.top }
        anchors.bottomMargin: 8
        anchors.leftMargin: 16; anchors.rightMargin: 16
        visible: root.shelf.length > 0
        height: Theme.borderWidth
        color: Theme.border
    }

    ListView {
        id: shelfList
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.margins: 14
        height: 74
        visible: root.shelf.length > 0
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.shelf

        delegate: Item {
            id: chip

            required property string modelData

            width: 64
            height: 74

            Rectangle {
                id: thumb
                anchors.horizontalCenter: parent.horizontalCenter
                width: 52; height: 52
                radius: 10
                color: Theme.surface
                border.width: Theme.borderWidth
                border.color: hover.hovered ? Theme.blue : Theme.border

                // drag back out into other apps as a real file drop
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction
                Drag.mimeData: ({ "text/uri-list": chip.modelData })

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.borderWidth
                    radius: 9
                    color: "transparent"
                    visible: root.isImage(chip.modelData)

                    Image {
                        anchors.fill: parent
                        source: chip.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: !root.isImage(chip.modelData)
                    text: "󰈔"
                    font.family: Theme.nerdFont
                    font.pixelSize: 20
                    color: Qt.alpha(Theme.foreground, 0.7)
                }

                HoverHandler { id: hover }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: Quickshell.execDetached(["xdg-open", chip.modelData])
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: root.removeUrl(chip.modelData)
                }
                DragHandler {
                    onActiveChanged: {
                        if (active) {
                            thumb.grabToImage(res => {
                                thumb.Drag.imageSource = res.url;
                                thumb.Drag.active = true;
                            });
                        } else {
                            thumb.Drag.active = false;
                        }
                    }
                }
            }

            Text {
                anchors { top: thumb.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                text: decodeURIComponent(chip.modelData.split("/").pop())
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 4
                color: Qt.alpha(Theme.foreground, 0.55)
            }
        }
    }

    // ── Drop target (topmost; transparent to normal mouse input) ──────
    DropArea {
        anchors.fill: parent
        onDropped: drop => {
            if (drop.hasUrls) {
                for (const u of drop.urls) root.addUrl(u.toString());
                drop.accept(Qt.CopyAction);
            }
        }
    }
}
