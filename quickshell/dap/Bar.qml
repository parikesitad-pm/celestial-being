import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 10; right: 10 }
    implicitHeight: 36
    exclusiveZone: 42
    color: "transparent"
    WlrLayershell.namespace: "dap-bar"

    readonly property var mon: Hyprland.monitorFor(screen)
    // Portrait screens can't fit every pill at full size.
    readonly property bool narrow: width < 1300

    component Pill: Rectangle {
        height: 36
        radius: 18
        color: Theme.glass
        border.width: 1
        border.color: Theme.stroke
    }
    component Label: Text {
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
    }

    // ───────── left: logo, name, workspaces, window ─────────
    Pill {
        id: left
        anchors.left: parent.left
        width: leftRow.implicitWidth + 28
        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 10
            Image {
                source: "file://" + Theme.assets + "cb-64.png"
                sourceSize: Qt.size(64, 64)
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                smooth: true; mipmap: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Label { visible: !bar.narrow; text: "dap_"; font.weight: Font.ExtraBold; font.letterSpacing: 0.5 }
            Row {
                spacing: 6
                Layout.leftMargin: 4
                Repeater {
                    // This screen's desktops only.
                    model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === bar.mon).sort((a, b) => a.id - b.id)
                    delegate: Rectangle {
                        required property var modelData
                        readonly property int wid: modelData.id
                        readonly property bool active: !!bar.mon && !!bar.mon.activeWorkspace && bar.mon.activeWorkspace.id === wid
                        readonly property bool used: modelData.toplevels.values.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        height: 8
                        width: active ? 24 : 8
                        radius: 4
                        color: active ? Ui.deskColor(wid) : (used ? Theme.subtext : Theme.tile)
                        Behavior on width { SpringAnimation { spring: 5; damping: 0.45; epsilon: 0.2 } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Ui.workspace(parent.wid)
                        }
                    }
                }
            }
            Label {
                id: deskLabel
                text: bar.mon && bar.mon.activeWorkspace ? Ui.deskName(bar.mon.activeWorkspace.id) : ""
                color: bar.mon && bar.mon.activeWorkspace ? Ui.deskColor(bar.mon.activeWorkspace.id) : Theme.accent
                Behavior on color { ColorAnimation { duration: 220 } }
            }
            Label {
                // Takes only the room left between the desktop name and the island.
                readonly property real room: bar.width - Ui.ccPillWidth - center.width - (deskLabel.x + deskLabel.width) - 66
                visible: room >= 60
                Layout.maximumWidth: Math.min(260, room)
                elide: Text.ElideRight
                color: Theme.subtext
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            }
        }
    }

    // ───────── center: the island (Island.qml) floats over this slot ─────────
    // Placeholder with the island's collapsed width, so the window title on the left stays clear of it.
    Item {
        id: center
        width: Ui.islandPillWidth
        height: 36
        x: (bar.width - width) / 2
    }

    // The right end (status + control center) is ControlCenter.qml, floating over the bar like the island.
}
