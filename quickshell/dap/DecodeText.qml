import QtQuick

// Text that resolves out of noise left to right, like __hud_decode in hud.fish.
// Call play() to run it again; monospace keeps the width steady while it scrambles.
Text {
    id: t
    property string target: ""
    property int frames: 14
    property int frame: frames
    readonly property var noise: ["▓", "▒", "░", "#", "%", "&", "@", "$", "=", "+", "0", "1"]

    function play() { frame = 0; tick.restart() }

    text: {
        if (frame >= frames) return target
        const solved = Math.floor(target.length * frame / frames)
        let out = target.slice(0, solved)
        for (let i = solved; i < target.length; i++)
            out += target[i] === " " ? " " : noise[(i * 7 + frame * 3) % noise.length]
        return out
    }

    Timer {
        id: tick
        interval: 30
        repeat: true
        onTriggered: if (++t.frame >= t.frames) stop()
    }
}
