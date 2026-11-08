import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    anchors { top: true }
    margins { top: 48 }
    implicitWidth: 340
    implicitHeight: 400
    color: "transparent"
    visible: Ui.calendar || card.opacity > 0.01
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-calendar"
    WlrLayershell.keyboardFocus: Ui.calendar ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab { windows: [win]; active: Ui.calendar; onCleared: Ui.cleared("calendar") }

    property date view: new Date(Ui.now.getFullYear(), Ui.now.getMonth(), 1)
    onVisibleChanged: if (visible && Ui.calendar) view = new Date(Ui.now.getFullYear(), Ui.now.getMonth(), 1)

    function build(v, today) { return Agenda.monthGrid(v, today) }
    function shift(n) { view = new Date(view.getFullYear(), view.getMonth() + n, 1) }

    Rectangle {
        id: card
        width: 320; height: 380
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 26
        color: Theme.glass
        border.width: 1; border.color: Theme.stroke
        opacity: Ui.calendar ? 1 : 0
        scale: Ui.calendar ? 1 : 0.92
        transformOrigin: Item.Top
        y: Ui.calendar ? 0 : -10
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { spring: 6; damping: 0.38; epsilon: 0.001 } }
        Behavior on y { SpringAnimation { spring: 6; damping: 0.38; epsilon: 0.05 } }
        focus: true
        Keys.onEscapePressed: Ui.calendar = false

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 18
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout { spacing: 0
                    Text { text: Qt.formatDateTime(win.view, "MMMM"); font.family: Theme.font; font.pixelSize: 26; font.weight: Font.Bold; color: Theme.text }
                    Text { text: Qt.formatDateTime(win.view, "yyyy"); font.family: Theme.font; font.pixelSize: 13; color: Theme.subtext }
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [{ g: "‹", n: -1 }, { g: "●", n: 0 }, { g: "›", n: 1 }]
                    delegate: Rectangle {
                        required property var modelData
                        width: 32; height: 32; radius: 16
                        color: ma.containsMouse ? Theme.tileHover : Theme.tile
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: modelData.g; color: Theme.text; font.pixelSize: modelData.n === 0 ? 9 : 20; font.family: Theme.font }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: modelData.n === 0 ? win.view = new Date(Ui.now.getFullYear(), Ui.now.getMonth(), 1) : win.shift(modelData.n) }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7; columnSpacing: 0; rowSpacing: 0
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: modelData; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.subtext
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                columns: 7; columnSpacing: 0; rowSpacing: 2
                Repeater {
                    model: win.build(win.view, Ui.now)
                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height, 38); height: width; radius: width / 2
                            color: modelData.today ? Theme.accent : (hov.containsMouse ? Theme.tile : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.d
                                font.family: Theme.font; font.pixelSize: 14
                                font.weight: modelData.today ? Font.Bold : Font.Normal
                                color: modelData.today ? "#04120d" : (modelData.cur ? ((index % 7) >= 5 ? Theme.orange : Theme.text) : Theme.subtext)
                                opacity: modelData.cur ? 1 : 0.4
                            }
                            MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
        }
    }
}
