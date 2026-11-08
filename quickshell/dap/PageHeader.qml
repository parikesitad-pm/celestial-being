import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    signal back()
    property string title: ""
    property bool busy: false   // sweeps the mono-eye while the page is loading
    Layout.fillWidth: true; spacing: 8
    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: bk.containsMouse ? Theme.tileHover : Theme.tile
        Text { anchors.centerIn: parent; text: Theme.g(0xF0141); font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.text; renderType: Text.NativeRendering }
        MouseArea { id: bk; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.back() } }
    Text { text: root.title; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.Bold; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; renderType: Text.NativeRendering }
    MonoEye { running: root.busy; Layout.rightMargin: 6 }
}
