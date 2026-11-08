import QtQuick
import "."

// One light pillar over a panel divider in the art: ignites once, then breathes until flared.
Item {
    id: beam

    property color tint
    property int igniteDelay: 0
    property real breathSeconds: 5

    function flare(strength) {
        flarePeak = strength
        flareRun.restart()
    }

    property real flarePeak: 1

    width: 170
    transform: Scale { id: stretch; origin.y: beam.height * 0.45; yScale: 0 }

    GlowSprite {
        id: halo
        anchors.fill: parent
        tint: beam.tint
        opacity: 0
    }

    Item {
        id: flash
        anchors.fill: parent
        opacity: 0

        GlowSprite {
            anchors.fill: parent
            tint: beam.tint
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 3
            height: parent.height
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.4; color: "#ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    SequentialAnimation {
        id: flareRun
        OpacityAnimator { target: flash; to: beam.flarePeak; duration: 80 }
        OpacityAnimator {
            target: flash; to: 0; duration: Tokens.flareDecay
            easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
        }
    }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: beam.igniteDelay }
        ScriptAction { script: beam.flare(1) }
        NumberAnimation {
            target: stretch; property: "yScale"; to: 1; duration: Tokens.ignite
            easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
        }
        ScriptAction { script: breath.start() }
    }

    SequentialAnimation {
        id: breath
        loops: Animation.Infinite
        OpacityAnimator {
            target: halo; to: 0.5; duration: beam.breathSeconds * 500
            easing.type: Easing.InOutSine
        }
        OpacityAnimator {
            target: halo; to: 0.15; duration: beam.breathSeconds * 500
            easing.type: Easing.InOutSine
        }
    }
}
