import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Region picker for screenshots and recordings (replaces slurp). Drag to select, drag inside to
// move, drag a corner to resize; Enter or double-click captures, Esc cancels. Outside the
// selection is dimmed and guide lines run from its edges to the screen edges.
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: -1
    visible: Ui.select !== ""
    // Outside the "dap-*" glass rule in hyprland.lua: a blurred overlay would hide what is being selected.
    WlrLayershell.namespace: "cb-region"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool recording: Ui.select === "record"
    readonly property color tint: recording ? Theme.transAmRed : Theme.gn
    // Selection in window coordinates; w = 0 means nothing selected yet.
    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0
    readonly property bool has: sw >= 4 && sh >= 4

    onVisibleChanged: { sx = 0; sy = 0; sw = 0; sh = 0; if (visible) keys.forceActiveFocus() }

    function capture() {
        if (!has) return
        const mon = Hyprland.monitorFor(win.screen)
        const ox = mon ? mon.x : 0, oy = mon ? mon.y : 0
        const geo = Math.round(ox + sx) + "," + Math.round(oy + sy) + " " + Math.round(sw) + "x" + Math.round(sh)
        const mode = recording ? "record-region" : "region"
        Ui.select = ""
        // Let the overlay unmap before grim reads the screen.
        Quickshell.execDetached(["sh", "-c", 'sleep 0.15; "$0" "$1" "$2"', Theme.scripts + "screenshot.sh", mode, geo])
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.select = ""
        Keys.onReturnPressed: win.capture()
        Keys.onEnterPressed: win.capture()

        // Dim everything outside the selection (the whole screen until one exists).
        component Shade: Rectangle { color: Qt.rgba(0, 0, 0, 0.45) }
        Shade { x: 0; y: 0; width: parent.width; height: win.has ? win.sy : parent.height }
        Shade { visible: win.has; x: 0; y: win.sy + win.sh; width: parent.width; height: parent.height - y }
        Shade { visible: win.has; x: 0; y: win.sy; width: win.sx; height: win.sh }
        Shade { visible: win.has; x: win.sx + win.sw; y: win.sy; width: parent.width - x; height: win.sh }

        // Guide lines from the selection's edges to the screen edges.
        component Guide: Rectangle { color: win.tint; opacity: 0.35; visible: win.has }
        Guide { x: 0; y: win.sy; width: parent.width; height: 1 }
        Guide { x: 0; y: win.sy + win.sh - 1; width: parent.width; height: 1 }
        Guide { x: win.sx; y: 0; width: 1; height: parent.height }
        Guide { x: win.sx + win.sw - 1; y: 0; width: 1; height: parent.height }

        Rectangle {
            visible: win.has
            x: win.sx; y: win.sy; width: win.sw; height: win.sh
            color: "transparent"
            radius: 4
            border.width: 2
            border.color: win.tint
        }

        // New selection: press on the dimmed area and drag.
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            property real ox: 0
            property real oy: 0
            onPressed: m => { ox = m.x; oy = m.y; win.sx = m.x; win.sy = m.y; win.sw = 0; win.sh = 0 }
            onPositionChanged: m => {
                win.sx = Math.min(ox, m.x); win.sy = Math.min(oy, m.y)
                win.sw = Math.abs(m.x - ox); win.sh = Math.abs(m.y - oy)
            }
        }
        // Move: drag inside the selection. Double-click captures.
        MouseArea {
            visible: win.has
            x: win.sx; y: win.sy; width: win.sw; height: win.sh
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property real ox: 0
            property real oy: 0
            onPressed: m => { ox = m.x; oy = m.y }
            onPositionChanged: m => {
                win.sx = Math.max(0, Math.min(keys.width - win.sw, win.sx + m.x - ox))
                win.sy = Math.max(0, Math.min(keys.height - win.sh, win.sy + m.y - oy))
            }
            onDoubleClicked: win.capture()
        }

        // Corner handles: drag to resize; the opposite corner stays put.
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            delegate: Rectangle {
                id: handle
                required property var modelData
                readonly property real cx: win.sx + modelData[0] * win.sw
                readonly property real cy: win.sy + modelData[1] * win.sh
                visible: win.has
                x: cx - width / 2; y: cy - height / 2
                width: 16; height: 16; radius: 8
                color: win.tint
                border.width: 3
                border.color: Qt.rgba(0, 0, 0, 0.55)
                scale: visible ? (grab.pressed ? 1.25 : 1) : 0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }
                MouseArea {
                    id: grab
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: (handle.modelData[0] === handle.modelData[1]) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                    property real ax: 0   // the fixed, opposite corner
                    property real ay: 0
                    onPressed: {
                        ax = win.sx + (1 - handle.modelData[0]) * win.sw
                        ay = win.sy + (1 - handle.modelData[1]) * win.sh
                    }
                    onPositionChanged: m => {
                        const p = mapToItem(keys, m.x, m.y)
                        win.sx = Math.min(ax, p.x); win.sy = Math.min(ay, p.y)
                        win.sw = Math.abs(p.x - ax); win.sh = Math.abs(p.y - ay)
                    }
                }
            }
        }

        // Size chip under the selection (above it when there is no room below).
        Rectangle {
            visible: win.has
            readonly property bool below: win.sy + win.sh + 44 < keys.height
            x: Math.min(keys.width - width - 8, win.sx + win.sw - width)
            y: below ? win.sy + win.sh + 12 : win.sy - height - 12
            width: sizeText.implicitWidth + 24; height: 28; radius: 14
            color: Theme.glassStrong
            border.width: 1; border.color: win.tint
            Text {
                id: sizeText
                anchors.centerIn: parent
                text: Math.round(win.sw) + " × " + Math.round(win.sh) + "   ↵ " + (win.recording ? "record" : "capture")
                font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: Theme.text
            }
        }

        // Hint until something is selected.
        Rectangle {
            visible: !win.has
            anchors.centerIn: parent
            width: hint.implicitWidth + 32; height: 40; radius: 20
            color: Theme.glassStrong
            border.width: 1; border.color: win.tint
            Text {
                id: hint
                anchors.centerIn: parent
                text: (win.recording ? "RECORD" : "CAPTURE") + " // drag to select · Esc to cancel"
                font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; font.letterSpacing: 0.5
                color: Theme.text
            }
        }
    }
}
