import QtQuick
import QtQuick.Layouts

// Quick-settings tile. `compact` stacks the icon over the label for rows of 3-4 tiles.
Rectangle {
    id: tile
    property string glyph: ""
    property string title: ""
    property string sub: ""
    property bool on: false
    property color onColor: Theme.accent
    property bool chevron: false
    property bool compact: false
    property bool interactive: true
    signal clicked()
    signal chevronClicked()

    readonly property color ink: on ? Theme.onTint : Theme.text
    readonly property color inkDim: on ? Theme.onTint : Theme.subtext

    implicitHeight: 60
    radius: 18
    opacity: interactive ? 1 : 0.55
    color: on ? onColor : (ma.containsMouse ? Theme.tileHover : Theme.tile)
    Behavior on color { ColorAnimation { duration: 160 } }
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    RowLayout {
        visible: !tile.compact
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: tile.chevron ? 28 : 10
        spacing: 8
        Rectangle {
            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
            color: tile.on ? Qt.rgba(0, 0, 0, 0.18) : Theme.tile
            Text { anchors.centerIn: parent; text: tile.glyph; font.family: Theme.iconFont; font.pixelSize: 16; color: tile.ink; renderType: Text.NativeRendering }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            Text { Layout.fillWidth: true; text: tile.title; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; color: tile.ink; elide: Text.ElideRight; renderType: Text.NativeRendering }
            Text { Layout.fillWidth: true; text: tile.sub; visible: text !== ""; font.family: Theme.font; font.pixelSize: 11; color: tile.inkDim; elide: Text.ElideRight; renderType: Text.NativeRendering }
        }
    }

    Column {
        visible: tile.compact
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 3
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28; height: 28; radius: 14
            color: tile.on ? Qt.rgba(0, 0, 0, 0.18) : Theme.tile
            Text { anchors.centerIn: parent; text: tile.glyph; font.family: Theme.iconFont; font.pixelSize: 15; color: tile.ink; renderType: Text.NativeRendering }
        }
        Text {
            width: parent.width; horizontalAlignment: Text.AlignHCenter; text: tile.title
            font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; color: tile.ink; elide: Text.ElideRight; renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: tile.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }

    // Separate hit zone: the tile body toggles, the chevron opens the sub page.
    Rectangle {
        visible: tile.chevron
        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
        width: 22; height: parent.height - 16; radius: 8
        color: chev.containsMouse ? Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, 0.14) : "transparent"
        Text { anchors.centerIn: parent; text: Theme.g(0xF0142); font.family: Theme.iconFont; font.pixelSize: 16; color: tile.ink; renderType: Text.NativeRendering }
        MouseArea {
            id: chev
            anchors.fill: parent; anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.chevronClicked()
        }
    }
}
