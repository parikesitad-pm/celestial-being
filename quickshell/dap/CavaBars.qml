import QtQuick
import Quickshell.Io

// Audio bars from cava, tinted with the window-border gradient as it travels.
// The cava process and the colour loop only run while `running` is true.
Item {
    id: root
    property bool running: false
    readonly property int bars: 24
    property var levels: []
    property real phase: 0

    NumberAnimation on phase {
        from: 0; to: 1
        duration: Theme.borderLoopMs
        loops: Animation.Infinite
        running: root.running
    }

    // Position 0..1 along the looping gradient → colour between neighbouring stops.
    function tint(pos) {
        const stops = Theme.border
        const x = (pos % 1) * stops.length
        const i = Math.floor(x), t = x - i
        const a = stops[i], b = stops[(i + 1) % stops.length]
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }

    Process {
        running: root.running
        command: ["cava", "-p", Qt.resolvedUrl("cava.conf").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(v => v !== "").map(Number)
        }
        onRunningChanged: if (!running) root.levels = []
    }

    Row {
        anchors.fill: parent
        spacing: 3
        Repeater {
            model: root.bars
            delegate: Rectangle {
                required property int index
                readonly property real level: (root.levels[index] || 0) / 100
                width: (root.width - (root.bars - 1) * 3) / root.bars
                height: root.height
                radius: 1.5
                color: root.tint(index / root.bars + root.phase)
                opacity: 0.5 + 0.5 * level
                transform: Scale { origin.y: root.height; yScale: Math.max(0.08, level) }
            }
        }
    }
}
