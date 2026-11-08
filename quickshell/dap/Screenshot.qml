import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// ⌘⇧5 toolbar
PanelWindow {
    id: win
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 120
    color: "transparent"
    visible: Ui.shot || bar.opacity > 0.01
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.shot ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: bar }

    function run(mode) {
        Ui.shot = false
        Ui.sh("sleep 0.35; " + Theme.scripts + "screenshot.sh " + mode)
    }

    Rectangle {
        id: bar
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 28 }
        width: row.implicitWidth + 24; height: 56; radius: 28
        color: Theme.glassStrong; border.width: 1; border.color: Theme.stroke
        opacity: Ui.shot ? 1 : 0
        scale: Ui.shot ? 1 : 0.92
        transform: Translate { y: Ui.shot ? 0 : 30; Behavior on y { SpringAnimation { spring: 6; damping: 0.4; epsilon: 0.01 } } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.001 } }
        focus: true
        Keys.onEscapePressed: Ui.shot = false

        component Btn: Rectangle {
            id: b
            property string label: ""
            property string glyph: ""
            property bool danger: false
            signal clicked()
            implicitWidth: lbl.implicitWidth + 28; implicitHeight: 40; radius: 20
            color: m.containsMouse ? Theme.tileHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            scale: m.pressed ? 0.94 : 1
            Behavior on scale { SpringAnimation { spring: 8; damping: 0.4; epsilon: 0.001 } }
            Text { id: lbl; anchors.centerIn: parent; text: b.glyph + "  " + b.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                   color: b.danger ? Theme.red : Theme.text }
            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent; spacing: 2
            Btn { glyph: "▣"; label: "Screen";    onClicked: win.run("full") }
            Btn { glyph: "▭"; label: "Window";    onClicked: win.run("window") }
            Btn { glyph: "⬚"; label: "Selection"; onClicked: { Ui.shot = false; Ui.select = "shot" } }
            Rectangle { width: 1; Layout.preferredHeight: 24; color: Theme.stroke }
            Btn { glyph: "●"; label: "Record screen";    onClicked: win.run("record") }
            Btn { glyph: "◉"; label: "Record selection"; onClicked: { Ui.shot = false; Ui.select = "record" } }
            Rectangle { width: 1; Layout.preferredHeight: 24; color: Theme.stroke }
            Btn { glyph: "✕"; label: ""; danger: true; onClicked: Ui.shot = false }
        }
    }
}
