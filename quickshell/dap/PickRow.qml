import QtQuick
import QtQuick.Layouts

Rectangle {
    id: pr
    property string title: ""
    property string sub: ""
    property bool current: false
    signal picked()
    Layout.fillWidth: true; implicitHeight: 44; radius: 14
    color: current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (prm.containsMouse ? Theme.tileHover : Theme.tile)
    Behavior on color { ColorAnimation { duration: 120 } }
    RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8
        Text { text: pr.title; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.text; elide: Text.ElideRight; Layout.fillWidth: true; renderType: Text.NativeRendering }
        Text { text: pr.sub; visible: text !== ""; font.family: Theme.font; font.pixelSize: 11; font.features: { "tnum": 1 }; color: Theme.subtext; renderType: Text.NativeRendering }
        Text { text: Theme.g(0xF012C); visible: pr.current; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.dark ? Theme.accent : Theme.text; renderType: Text.NativeRendering } }
    MouseArea { id: prm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pr.picked() }
}
