import QtQuick

// DecodeText with a red/cyan channel split that jitters while it resolves, like a
// mobile suit's systems check coming back online. Calm once the text has settled.
Item {
    id: g
    property alias target: main.target
    property alias font: main.font
    property color color: Theme.text
    readonly property bool busy: main.frame < main.frames
    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight
    function play() { main.play() }

    Text {
        text: main.text; font: main.font
        color: Theme.red
        opacity: g.busy ? 0.75 : 0
        transform: Translate { x: g.busy ? (main.frame % 2 ? 2 : -1) : 0 }
    }
    Text {
        text: main.text; font: main.font
        color: "#00f0ff"
        opacity: g.busy ? 0.75 : 0
        transform: Translate { x: g.busy ? (main.frame % 2 ? -2 : 1) : 0 }
    }
    DecodeText { id: main; color: g.color }
}
