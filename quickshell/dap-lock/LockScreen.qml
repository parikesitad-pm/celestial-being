import QtQuick
import Quickshell
import "components/atoms"
import "components/organisms"

// What one monitor shows while locked. Knows nothing about PAM or the session lock itself.
Rectangle {
    id: screen

    property string user
    property date now: new Date()

    signal passwordEntered(string password)
    signal finished()

    function reject() {
        stack.field.fail()
        gnField.fail()
    }
    function accept() { leave.start() }

    color: Tokens.night

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: screen.now = new Date()
    }

    Item {
        id: scene
        anchors.fill: parent

        GnField {
            id: gnField
            anchors.fill: parent
            art: Qt.resolvedUrl("assets/gundam-lock.png")
        }

        LockStack {
            id: stack
            anchors.fill: parent
            now: screen.now
            user: screen.user
            avatar: Qt.resolvedUrl("assets/avatar.jpg")
            onKeyed: (x, y) => gnField.keystroke(x, y)
            onSubmitted: {
                gnField.charge()
                chargeUp.restart()
            }
        }
    }

    Timer {
        id: chargeUp
        interval: Tokens.charge
        onTriggered: screen.passwordEntered(stack.field.text)
    }

    SequentialAnimation {
        id: leave
        OpacityAnimator {
            target: scene
            to: 0
            duration: Tokens.fadeOut
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.macSoft
        }
        ScriptAction { script: screen.finished() }
    }

    Component.onCompleted: stack.field.forceActiveFocus()
}
