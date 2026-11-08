import QtQuick
import "../atoms"

Row {
    id: clock

    property date time
    readonly property string digits: Qt.formatTime(time, "HHmm")

    RollDigit { value: clock.digits[0] }
    RollDigit { value: clock.digits[1] }

    Text {
        id: colon
        text: ":"
        color: "#ffffff"
        font { family: Tokens.sans; pixelSize: 96; weight: Font.Bold }

        // Same 2 s pulse as the colon in scripts/lock-clock.sh on the lock screen.
        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            OpacityAnimator { target: colon; from: 1; to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
            OpacityAnimator { target: colon; from: 0.35; to: 1; duration: 1000; easing.type: Easing.InOutSine }
        }
    }

    RollDigit { value: clock.digits[2] }
    RollDigit { value: clock.digits[3] }
}
