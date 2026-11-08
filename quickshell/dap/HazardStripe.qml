import QtQuick

// Moving caution tape, like the ◤◢ banner in the terminal boot sequence (hud.fish).
// Bars are sheared once; only a translate moves, and only while `running`.
Item {
    id: tape
    property bool running: false
    property color color: Theme.gold
    readonly property int period: 14   // one bar + one gap
    clip: true
    implicitHeight: 8

    Item {
        id: belt
        height: tape.height
        x: -tape.period - tape.height
        width: tape.width + 2 * tape.period + 2 * tape.height
        transform: [
            Matrix4x4 { matrix: Qt.matrix4x4(1, -1, 0, tape.height, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) },
            Translate { id: shift }
        ]
        Repeater {
            model: Math.ceil(belt.width / tape.period)
            delegate: Rectangle {
                required property int index
                x: index * tape.period
                width: tape.period / 2
                height: tape.height
                color: tape.color
            }
        }
    }

    NumberAnimation {
        target: shift; property: "x"
        from: 0; to: tape.period
        duration: 700
        loops: Animation.Infinite
        running: tape.running && tape.visible
    }
}
