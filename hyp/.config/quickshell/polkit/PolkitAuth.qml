import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Polkit authentication agent — bottom-sheet style.
//
// Swoops up from the bottom on auth request. The padlock icon (same canvas as
// the lock screen) morphs into a green tick on success, then the sheet swoops
// back down. Wrong password shakes the input and reverts the padlock.
//
// Requires hyprpolkitagent to be disabled:
//   systemctl --user disable --now hyprpolkitagent.service
Scope {
    id: root

    PolkitAgent {
        id: agent
        path: "/org/quickshell/polkitagent"
        onAuthenticationRequestStarted: {
            root.submitting = false
            root.authOk     = false
            root.authError  = false
            root.cancelled  = false
        }
    }

    // ── State ─────────────────────────────────────────────────────────────────
    property bool dialogShown: false   // drives visible + glide anim
    property bool submitting:  false   // password submitted, unlock anim playing
    property bool authOk:      false   // polkit confirmed success
    property bool authError:   false   // wrong password
    property bool cancelled:   false   // user explicitly cancelled

    // Fires when something wants the sheet to glide back down
    signal exitRequested()
    // Fires on implicit success (fingerprint) so fpIcon can start its morph
    signal authSucceeded()

    function cancel() {
        root.cancelled = true
        agent.flow?.cancelAuthenticationRequest()
        root.exitRequested()
    }

    // Watch agent active state
    Connections {
        target: agent
        function onIsActiveChanged() {
            if (agent.isActive) {
                root.dialogShown = true
            } else {
                if (root.cancelled) return          // already exiting, ignore
                root.authOk = true
                if (!root.submitting) {
                    // Fingerprint (or other implicit) success — morph wasn't
                    // started by onSubmittingChanged, so kick it off now.
                    root.authSucceeded()
                }
                // Password path: morph already playing via onSubmittingChanged;
                // authOk = true means morphComplete will call exitRequested.
            }
        }
    }

    // Wrong password
    Connections {
        target: agent.flow
        enabled: agent.flow !== null
        function onSupplementaryIsErrorChanged() {
            if ((agent.flow?.supplementaryIsError ?? false) && root.submitting) {
                root.submitting = false
                root.authError  = true
            }
        }
        function onIsResponseRequiredChanged() {}   // handled via submitting state
    }

    // ── Per-screen overlay ────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: root.dialogShown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            color: "transparent"

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "quickshell:polkit"
            WlrLayershell.keyboardFocus: root.dialogShown
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            // ── Glide animations ─────────────────────────────────────────────
            // Enter: OutExpo — arrives fast, decelerates to a near-stop at rest.
            // Exit:  InExpo  — barely moves then accelerates off-screen quickly.
            ParallelAnimation {
                id: enterAnim
                NumberAnimation {
                    target: cardSlide; property: "y"
                    to: 0; duration: 480; easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: card; property: "opacity"
                    to: 1; duration: 220; easing.type: Easing.OutCubic
                }
            }
            SequentialAnimation {
                id: exitAnim
                ParallelAnimation {
                    NumberAnimation {
                        target: cardSlide; property: "y"
                        to: win.height; duration: 260; easing.type: Easing.InExpo
                    }
                    NumberAnimation {
                        target: card; property: "opacity"
                        to: 0; duration: 180; easing.type: Easing.InCubic
                    }
                }
                ScriptAction { script: root.dialogShown = false }
            }

            Connections {
                target: root
                function onExitRequested() {
                    enterAnim.stop()
                    exitAnim.restart()
                }
                function onDialogShownChanged() {
                    if (!root.dialogShown) return
                    // Reset per-screen state on each new request
                    fpIcon.morph  = 0
                    fpIcon.scale  = 1.0
                    pwInput.text  = ""
                    cardSlide.y   = win.height
                    card.opacity  = 0
                    enterAnim.restart()
                    focusTimer.restart()
                }
            }

            Shortcut {
                sequence:    "Escape"
                enabled:     root.dialogShown && !root.submitting
                onActivated: root.cancel()
            }

            Timer { id: focusTimer; interval: 80; onTriggered: pwInput.forceActiveFocus() }

            // Scrim
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.52)
                opacity: root.dialogShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 280 } }
            }

            // ── Card ────────────────────────────────────────────────────────
            Rectangle {
                id: card
                width: 360
                anchors {
                    bottom:           parent.bottom
                    bottomMargin:     72
                    horizontalCenter: parent.horizontalCenter
                }
                implicitHeight: col.implicitHeight + 48
                height:         implicitHeight
                radius:         Theme.popupRadius
                color:          Theme.surface
                border.color:   Theme.border
                border.width:   Theme.borderWidth

                transform: Translate { id: cardSlide; y: 800 }

                ColumnLayout {
                    id: col
                    anchors {
                        top:   parent.top;   topMargin:   24
                        left:  parent.left;  leftMargin:  24
                        right: parent.right; rightMargin: 24
                    }
                    spacing: 14

                    // What's requesting auth
                    Text {
                        Layout.fillWidth:    true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            const m = agent.flow?.message ?? ""
                            return m !== "" ? m : "Authentication Required"
                        }
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight:    Font.DemiBold
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }

                    // Action ID — tiny, dimmed
                    Text {
                        Layout.fillWidth:    true
                        horizontalAlignment: Text.AlignHCenter
                        visible: (agent.flow?.actionId ?? "") !== ""
                        text:    agent.flow?.actionId ?? ""
                        font.family:    Theme.font
                        font.pixelSize: 10
                        color: Qt.alpha(Theme.foreground, 0.28)
                        elide: Text.ElideMiddle
                    }

                    // ── Input row: password pill + padlock canvas ───────────
                    Row {
                        Layout.fillWidth: true
                        spacing: 10

                        // Password pill (same proportions as lock screen)
                        Rectangle {
                            id: inputBox
                            width:  parent.width - fpIcon.width - parent.spacing
                            height: 42
                            radius: height / 2
                            color:  Qt.alpha(Theme.foreground, 0.04)
                            border.width: 1
                            border.color: root.authError
                                ? Qt.alpha(Theme.red, 0.65)
                                : (pwInput.activeFocus
                                    ? Qt.alpha(Theme.foreground, 0.45)
                                    : Qt.alpha(Theme.foreground, 0.18))
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            transform: Translate { id: shakeT }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 40 }
                                NumberAnimation { target: shakeT; property: "x"; to:  10; duration: 40 }
                                NumberAnimation { target: shakeT; property: "x"; to:  -6; duration: 40 }
                                NumberAnimation { target: shakeT; property: "x"; to:   4; duration: 40 }
                                NumberAnimation { target: shakeT; property: "x"; to:   0; duration: 40 }
                            }

                            TextInput {
                                id: pwInput
                                anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode:          TextInput.Password
                                font.family:       Theme.font
                                font.pixelSize:    Theme.fontSize
                                color:             Theme.foreground
                                enabled:           !root.submitting
                                clip:              true

                                onAccepted: {
                                    if (!(agent.flow?.isResponseRequired ?? false)) return
                                    root.submitting = true
                                    root.authOk     = false
                                    root.authError  = false
                                    agent.flow.submit(text)
                                    text = ""
                                }

                                // Placeholder
                                Text {
                                    anchors.fill:      parent
                                    verticalAlignment: Text.AlignVCenter
                                    text:    agent.flow?.inputPrompt ?? "Password"
                                    font:    pwInput.font
                                    color:   Qt.alpha(Theme.foreground, 0.22)
                                    visible: pwInput.text === "" && !pwInput.activeFocus
                                }
                            }
                        }

                        // ── Fingerprint → tick ───────────────────────────────
                        FingerprintIcon {
                            id: fpIcon
                            width: 32; height: 32
                            scanning:  !root.submitting && !root.authOk
                            iconColor: root.authError ? Theme.red : Theme.blue

                            // Swoop out after tick completes
                            onMorphComplete: { if (root.authOk) root.exitRequested() }

                            Connections {
                                target: root
                                function onSubmittingChanged() {
                                    if (root.submitting) {
                                        fpIcon.revertAnim.stop()
                                        fpIcon.unlockAnim.restart()
                                    } else if (!root.authOk) {
                                        fpIcon.unlockAnim.stop()
                                        fpIcon.revertAnim.restart()
                                        shakeAnim.restart()
                                    }
                                }
                                // Fingerprint success: morph wasn't started by
                                // onSubmittingChanged, so start it here.
                                function onAuthSucceeded() {
                                    fpIcon.revertAnim.stop()
                                    fpIcon.unlockAnim.restart()
                                }
                            }
                        }
                    }

                    // Spacing before cancel
                    Item { Layout.preferredHeight: 2 }

                    // Cancel link
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:    "Cancel"
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        color: cancelMo.containsMouse
                            ? Qt.alpha(Theme.foreground, 0.55)
                            : Qt.alpha(Theme.foreground, 0.28)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        MouseArea {
                            id: cancelMo
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.cancel()
                        }
                    }
                }
            }
        }
    }
}
