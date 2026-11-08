import QtQuick
import "../atoms"

FocusScope {
    id: field

    property string placeholder
    property bool capsLock: false
    property bool pending: false
    property bool failed: false
    property alias text: input.text
    readonly property int dotCount: dots.count

    signal submitted(string password)
    signal keyed()

    function fail() {
        pending = false
        failed = true
        input.clear()
        input.forceActiveFocus()
        shake.restart()
    }

    width: 300
    height: 52
    transform: Translate { id: nudge }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Tokens.fieldFill
    }

    GradientRing {
        anchors.fill: parent
        thickness: 2
        colorA: field.failed ? Tokens.red : field.pending ? Tokens.orange : Tokens.green
        colorB: field.failed ? Tokens.purple : field.pending ? Tokens.green : Tokens.blue
        colorC: field.failed ? Tokens.red : field.pending ? Tokens.orange : Tokens.purple
        loopSeconds: field.pending ? 1.2 : Tokens.borderLoop
        Behavior on colorA { ColorAnimation { duration: Tokens.colorShift } }
        Behavior on colorB { ColorAnimation { duration: Tokens.colorShift } }
        Behavior on colorC { ColorAnimation { duration: Tokens.colorShift } }
    }

    // The real input is invisible: dots are drawn below so each one can animate on its own.
    TextInput {
        id: input
        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        readOnly: field.pending
        selectByMouse: false
        cursorDelegate: Item {}
        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        Accessible.role: Accessible.EditableText
        Accessible.name: "Password for " + field.placeholder
        Accessible.passwordEdit: true

        onTextChanged: {
            if (text.length > 0)
                field.failed = false
            if (text.length > dots.count)
                field.keyed()
            // Append or trim instead of rebinding a count, or Repeater rebuilds every dot per key.
            while (dots.count < text.length)
                dots.append({})
            if (dots.count > text.length)
                dots.remove(text.length, dots.count - text.length)
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true
                if (text.length > 0 && !field.pending) {
                    field.pending = true
                    field.submitted(text)
                }
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true
                if (!field.pending)
                    clear()
            }
        }
    }

    ListModel { id: dots }

    Item {
        id: track

        readonly property real inset: field.capsLock ? 56 : 24
        readonly property real gap: 17.5
        readonly property real room: field.width - 2 * inset - 13
        // Long passwords tighten the spacing and shrink the dots, so they neither leave the field nor merge.
        readonly property real step: dots.count > 1 ? Math.min(gap, room / (dots.count - 1)) : gap
        readonly property real dotSize: Math.min(13, step * 0.7)

        anchors.fill: parent

        Repeater {
            id: dotRepeater
            model: dots

            Rectangle {
                required property int index

                width: track.dotSize
                height: track.dotSize
                radius: track.dotSize / 2
                y: (track.height - height) / 2
                x: (track.width - width) / 2 + (index - (dots.count - 1) / 2) * track.step
                color: Tokens.ink

                Behavior on x {
                    NumberAnimation {
                        duration: Tokens.dots
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
                    }
                }
                ParallelAnimation {
                    running: true
                    ScaleAnimator {
                        target: parent; from: 0.4; to: 1; duration: Tokens.dots
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
                    }
                    OpacityAnimator { target: parent; from: 0; to: 1; duration: Tokens.dots }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: dots.count === 0
        text: field.failed ? "Login failed. Try again." : field.placeholder
        color: field.failed ? "#ff9db0" : Tokens.ink
        opacity: field.failed ? 1 : 0.65
        font { family: Tokens.sans; pixelSize: 16; italic: true }
    }

    Text {
        anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
        visible: field.capsLock
        text: "CAPS"
        color: Tokens.orange
        font { family: Tokens.mono; pixelSize: 11; bold: true }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: nudge; property: "x"; to: -8; duration: 50 }
        NumberAnimation { target: nudge; property: "x"; to: 8; duration: 70 }
        NumberAnimation { target: nudge; property: "x"; to: -4; duration: 60 }
        NumberAnimation { target: nudge; property: "x"; to: 0; duration: 60 }
    }
}
