import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Checks one password against PAM. The password is dropped as soon as PAM has it.
Scope {
    id: auth

    property string config: "hyprlock"
    property string configDirectory: "/etc/pam.d"
    property string pending

    signal succeeded()
    signal failed()

    function submit(password) {
        pending = password
        if (!pam.start()) {
            pending = ""
            failed()
        }
    }

    PamContext {
        id: pam
        config: auth.config
        configDirectory: auth.configDirectory
        onPamMessage: {
            if (!responseRequired)
                return
            respond(auth.pending)
            auth.pending = ""
        }
        onCompleted: (result) => {
            auth.pending = ""
            if (result === PamResult.Success)
                auth.succeeded()
            else
                auth.failed()
        }
        onError: {
            auth.pending = ""
            auth.failed()
        }
    }
}
