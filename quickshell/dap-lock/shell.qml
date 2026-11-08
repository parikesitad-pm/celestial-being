import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Animated session lock, run as its own process so it uses no memory while unlocked.
// Start it with the lock.sh launcher, which falls back to hyprlock if this cannot lock.
ShellRoot {
    id: root

    // A live reload must never touch a running lock.
    settings.watchFiles: false

    LockAuth {
        id: auth
        onSucceeded: session.accepted()
        onFailed: session.rejected()
    }

    WlSessionLock {
        id: session

        signal accepted()
        signal rejected()

        locked: true

        WlSessionLockSurface {
            color: "black"

            LockScreen {
                id: lockScreen
                anchors.fill: parent
                user: Quickshell.env("USER")
                onPasswordEntered: (password) => auth.submit(password)
                onFinished: {
                    session.locked = false
                    Qt.quit()
                }

                Connections {
                    target: session
                    function onAccepted() { lockScreen.accept() }
                    function onRejected() { lockScreen.reject() }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"
        function secure(): bool { return session.secure }
    }
}
