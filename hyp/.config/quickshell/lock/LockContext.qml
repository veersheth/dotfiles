import Quickshell
import Quickshell.Services.Pam
import QtQuick

// Auth state shared by all lock surfaces. Runs two PAM conversations in
// parallel, hyprlock-style: the system swaylock service arms the fingerprint
// sensor while a password-only config handles typed input, so neither
// blocks the other.
Scope {
    id: root

    signal unlocked()
    signal failed()

    property string status: ""
    property bool   authenticating: false
    property bool   succeeded: false
    property string currentText: ""

    // brief green success beat before the lock actually releases
    function succeed() {
        status = "";
        authenticating = false;
        succeeded = true;
        successDelay.restart();
    }

    Timer {
        id: successDelay
        interval: 680   // covers the padlock bounce
        onTriggered: root.unlocked()
    }

    // Whether the lock is actively using this context. Aborted pam_fprintd
    // conversations linger until fprintd's own timeout (abort can't
    // interrupt a blocked D-Bus verify), so results may arrive from zombie
    // conversations long after unlock — armed gates them out.
    property bool armed: false

    // idempotent: called from the IPC entry point and from every lock
    // surface on creation, whichever happens first
    function begin() {
        if (armed) return;
        console.log("[lock] begin(): arming fingerprint");
        reset();
        armed = true;
        fprintWatch.start();
    }

    function end() {
        armed = false;
        pam.abort();
        fprint.abort();
        fprintWatch.stop();
        reset();
    }

    function reset() {
        status = "";
        authenticating = false;
        succeeded = false;
        currentText = "";
    }

    function submit() {
        if (authenticating || currentText === "") return;
        authenticating = true;
        status = "";
        pam.start();
    }

    // Password-only conversation. Custom config skips pam_fprintd so it
    // never fights the fingerprint context for the sensor.
    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: if (responseRequired) respond(root.currentText)

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.succeed();
            } else {
                root.authenticating = false;
                root.currentText = "";
                root.status = "Incorrect password";
                root.failed();
            }
        }
        onError: {
            root.authenticating = false;
            root.status = "Authentication error";
            root.failed();
        }
    }

    // Fingerprint conversation via the system swaylock service, which tries
    // pam_fprintd first. When the sensor phase gives up (pam falls through
    // and prompts for a password instead) we abort and re-arm the sensor.
    // exposed for `qs ipc call lock testFprint` — arms the sensor unlocked
    function testFprint() {
        armed = true;
        fprintWatch.start();
    }

    PamContext {
        id: fprint
        config: "swaylock"

        onPamMessage: {
            console.log(`[lock] fprint msg: "${message}" respReq=${responseRequired} err=${messageIsError} armed=${root.armed}`);
            if (!root.armed) return;
            if (responseRequired) {
                // sensor phase over, pam fell through to the password
                // prompt — bail out; the watchdog re-arms once we exit
                abort();
            } else if (message !== "") {
                root.status = message;   // "Place your finger on …"
            }
        }
        onCompleted: result => {
            console.log(`[lock] fprint completed: ${result} (success=${PamResult.Success}) armed=${root.armed}`);
            if (result === PamResult.Success && root.armed) root.succeed();
            // failures need no handling — the watchdog re-arms the sensor
        }
        onError: error => console.log(`[lock] fprint error: ${error} active=${fprint.active}`)
    }

    // Keeps the sensor armed while locked: starts the conversation as soon
    // as no previous one (including a lingering zombie) is still running.
    Timer {
        id: fprintWatch
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.armed && !root.succeeded && !fprint.active)
                fprint.start();
        }
    }
}
