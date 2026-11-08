import QtQuick
import "."

// Wraps one block of the lock stack and plays its entrance once.
Item {
    id: block

    property int delay: 0

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    opacity: 0
    transform: Translate { id: shift; y: 14 }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: block.delay }
        ParallelAnimation {
            OpacityAnimator {
                target: block; to: 1; duration: Tokens.fadeIn
                easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
            }
            NumberAnimation {
                target: shift; property: "y"; to: 0; duration: Tokens.fadeIn
                easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
            }
        }
    }
}
