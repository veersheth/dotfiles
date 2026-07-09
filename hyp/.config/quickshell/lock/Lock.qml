import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Session lock (ext-session-lock-v1). Trigger with `qs ipc call lock lock`;
// unlocks via password or fingerprint (see LockContext).
Scope {
    id: root

    LockContext {
        id: lockContext
        onUnlocked: {
            sessionLock.locked = false;
            lockContext.end();
        }
    }

    // NOTE: don't hook begin()/end() to onLockedChanged — on this
    // quickshell version it never fires with locked=true and emits
    // spurious false events, so arming is driven explicitly instead.
    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            color: "black"
            LockSurface {
                anchors.fill: parent
                ctx: lockContext
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            console.log(`[lock] ipc lock() called, locked was ${sessionLock.locked}`);
            sessionLock.locked = true;
            lockContext.begin();
        }
        // debug: arm the fingerprint PAM conversation without locking
        function testFprint(): void { lockContext.testFprint() }
    }
}
