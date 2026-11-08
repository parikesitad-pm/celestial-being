import QtQuick

// Zaku mono-eye: a pink light sweeping along a dark visor slit while something is loading.
// Fades out when idle and stops animating once hidden.
Rectangle {
    id: eye
    property bool running: false
    implicitWidth: 56
    implicitHeight: 8
    radius: 4
    color: Qt.rgba(0, 0, 0, 0.45)
    border.width: 1
    border.color: Theme.stroke
    clip: true
    opacity: running ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: eye.running ? 200 : 150 } }

    Rectangle {
        id: dot
        y: (eye.height - height) / 2
        width: 14; height: 6; radius: 3
        color: Theme.monoEye
        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 12; radius: 6
            color: Theme.monoEye
            opacity: 0.3
        }
        SequentialAnimation on x {
            running: eye.visible
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: eye.width - dot.width - 1; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
        }
    }
}
