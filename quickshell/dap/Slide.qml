import QtQuick

// Pill slider. The fill never drops below one pill height, so the icon always sits on it,
// and the 0-100 range maps onto the remaining width.
Rectangle {
    id: sl
    property real value: 0
    property string glyph: ""
    property bool muted: false
    property bool picker: false
    property real glyphTurn: 0   // degrees; the brightness sun turns with its value
    signal moved(real v)
    signal glyphClicked()
    signal pickerClicked()

    readonly property color inkOnFill: muted ? Theme.text : (Theme.dark ? "#101624" : "#f2f6ff")

    implicitHeight: 40
    radius: height / 2
    color: Theme.tile
    // Swells a little while held, like a physical fader under a thumb.
    scale: drag.pressed ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: drag.pressed ? 180 : 240; easing.type: Easing.OutExpo } }

    // Icon swaps when the level crosses a tier (low / mid / high); each swap gets a short pop.
    onGlyphChanged: glyphPop.restart()
    NumberAnimation {
        id: glyphPop
        target: glyphText; property: "scale"
        from: 1.3; to: 1; duration: 260; easing.type: Easing.OutExpo
    }

    Rectangle {
        id: fill
        height: parent.height; radius: height / 2
        width: sl.height + (sl.width - sl.height) * Math.max(0, Math.min(1, sl.value / 100))
        color: Theme.text
        opacity: sl.muted ? 0.3 : 0.92
        // Hardware keys and other apps move the value in 5% steps; glide instead of jumping.
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Text {
        id: glyphText
        anchors.centerIn: glyphZone
        rotation: sl.glyphTurn
        Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }
        text: sl.glyph
        font.family: Theme.iconFont; font.pixelSize: 16
        color: sl.inkOnFill
        renderType: Text.NativeRendering
    }
    Text {
        id: readout
        x: 40; height: sl.height; verticalAlignment: Text.AlignVCenter
        text: sl.muted ? "Muted" : Math.round(sl.value) + "%"
        font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
        color: Theme.text
        renderType: Text.NativeRendering
    }
    // Second copy clipped to the fill, so the color changes exactly at the fill's edge.
    Item {
        width: fill.width; height: sl.height; clip: true
        Text {
            x: readout.x; height: readout.height; verticalAlignment: readout.verticalAlignment
            text: readout.text; font: readout.font
            color: sl.inkOnFill
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) { sl.moved(Math.max(0, Math.min(100, (mx - sl.height) / (sl.width - sl.height) * 100))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
    }
    MouseArea {
        id: glyphZone
        width: sl.height; height: sl.height
        cursorShape: Qt.PointingHandCursor
        onClicked: sl.glyphClicked()
    }
    Rectangle {
        visible: sl.picker
        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
        width: 32; height: 32; radius: 16
        readonly property color ink: fill.width >= sl.width - 20 && !sl.muted ? sl.inkOnFill : Theme.text
        color: pk.containsMouse ? Qt.rgba(ink.r, ink.g, ink.b, 0.14) : "transparent"
        Text { anchors.centerIn: parent; text: Theme.g(0xF0142); font.family: Theme.iconFont; font.pixelSize: 16; color: parent.ink; renderType: Text.NativeRendering }
        MouseArea { id: pk; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sl.pickerClicked() }
    }
}
