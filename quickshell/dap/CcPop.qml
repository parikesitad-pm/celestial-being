import QtQuick

// Status icon that pops when `watch` changes and sends out a ring when `ping` turns true.
Item {
    id: pop
    property alias text: glyph.text
    property alias color: glyph.color
    property var watch
    property bool ping: false
    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight
    onWatchChanged: bump.restart()
    onPingChanged: if (ping) wave.restart()

    Rectangle {
        id: ring
        anchors.centerIn: parent
        width: 22; height: 22; radius: 11
        color: "transparent"
        border.width: 1.5; border.color: glyph.color
        opacity: 0; scale: 0.6
    }
    Text {
        id: glyph
        anchors.centerIn: parent
        font.family: Theme.iconFont
        font.pixelSize: 15
        color: Theme.text
    }
    SequentialAnimation {
        id: bump
        NumberAnimation { target: glyph; property: "scale"; to: 1.45; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: glyph; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }
    ParallelAnimation {
        id: wave
        NumberAnimation { target: ring; property: "scale"; from: 0.6; to: 2.3; duration: 700; easing.type: Easing.OutCubic }
        NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 700; easing.type: Easing.InQuad }
    }
}
