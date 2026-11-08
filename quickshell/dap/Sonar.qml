import QtQuick

// A sonar ping from this item's position: two rings expand and fade, the second a beat later.
// Scale and opacity only; nothing runs between pings.
Item {
    id: sonar
    property color color: Theme.accent
    property real reach: 460
    signal pinged
    function play() { pinged() }

    Repeater {
        model: 2
        delegate: Rectangle {
            id: ring
            required property int index
            width: sonar.reach * 2; height: width; radius: width / 2
            x: -width / 2; y: -height / 2
            color: "transparent"
            border.width: 2; border.color: sonar.color
            scale: 0; opacity: 0
            SequentialAnimation {
                id: ping
                PauseAnimation { duration: ring.index * 170 }
                ParallelAnimation {
                    NumberAnimation { target: ring; property: "scale"; from: 0.02; to: 1; duration: 850; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "opacity"; from: 0.75; to: 0; duration: 850; easing.type: Easing.InQuad }
                }
            }
            Connections { target: sonar; function onPinged() { ping.restart() } }
        }
    }
}
