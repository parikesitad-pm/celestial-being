import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: win
    anchors { bottom: true }
    margins { bottom: 90 }
    implicitWidth: 260; implicitHeight: 64
    color: "transparent"
    exclusiveZone: -1
    visible: pill.opacity > 0.01
    mask: Region {}                       // never steal clicks
    WlrLayershell.namespace: "dap-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool shown: false
    Connections { target: win.audio; ignoreUnknownSignals: true
        function onVolumeChanged() { win.pop() } function onMutedChanged() { win.pop() } }
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: win.armed = true }   // ignore the initial value burst
    function pop() { if (!armed) return; shown = true; hide.restart() }
    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: 240; height: 52; radius: 26
        color: Theme.glassStrong; border.width: 1; border.color: Theme.stroke
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.85
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { SpringAnimation { spring: 8; damping: 0.4; epsilon: 0.001 } }
        Text { x: 18; anchors.verticalCenter: parent.verticalCenter; font.family: Theme.iconFont; font.pixelSize: 20; color: Theme.text
               text: win.audio && !win.audio.muted ? Theme.g(0xF057E) : Theme.g(0xF075F) }
        Rectangle {
            x: 54; width: parent.width - 54 - 20; height: 8; radius: 4; anchors.verticalCenter: parent.verticalCenter; color: Theme.tile
            Rectangle { height: parent.height; radius: 4; color: Theme.text
                width: parent.width * Math.min(1, win.audio && !win.audio.muted ? win.audio.volume : 0)
                Behavior on width { NumberAnimation { duration: 100 } } }
        }
    }
}
