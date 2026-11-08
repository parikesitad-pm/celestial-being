import QtQuick
import "."

// One clock digit. A new value rolls in from below and passes through GN green on the way.
Item {
    id: digit

    property string value
    property int pixelSize: 96

    width: metrics.advanceWidth
    height: current.implicitHeight
    clip: true

    onValueChanged: {
        if (current.text === "") {
            current.text = value
            return
        }
        outgoing.text = current.text
        current.text = value
        roll.restart()
    }
    Component.onCompleted: current.text = value

    TextMetrics {
        id: metrics
        font: current.font
        text: "0"
    }

    Text {
        id: outgoing
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0
        color: "#ffffff"
        font: current.font
    }

    Text {
        id: current
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#ffffff"
        font { family: Tokens.sans; pixelSize: digit.pixelSize; weight: Font.Bold; features: { "tnum": 1 } }
    }

    ParallelAnimation {
        id: roll
        YAnimator {
            target: current; from: digit.height * 0.7; to: 0; duration: Tokens.digitRoll
            easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
        }
        YAnimator {
            target: outgoing; from: 0; to: -digit.height * 0.7; duration: Tokens.digitRoll * 0.75
            easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.macSoft
        }
        OpacityAnimator { target: outgoing; from: 1; to: 0; duration: Tokens.digitRoll * 0.75 }
        SequentialAnimation {
            ColorAnimation { target: current; property: "color"; to: Tokens.green; duration: 1 }
            ColorAnimation { target: current; property: "color"; to: "#ffffff"; duration: Tokens.digitRoll * 1.6 }
        }
    }
}
