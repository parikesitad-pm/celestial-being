import QtQuick
import Quickshell
import Quickshell.Hyprland

// Dock right-click menu: pin state, new window, close.
Rectangle {
    id: menu
    required property var dock

    visible: dock.menuKey !== ""
    focus: visible
    Keys.onEscapePressed: dock.menuKey = ""
    width: menuColumn.width + 12; height: menuColumn.height + 12
    radius: 16
    color: Theme.glassStrong; border.width: 1; border.color: Theme.stroke

    component MenuRow: Rectangle {
        id: rowItem
        property string label: ""
        property color tint: Theme.text
        signal picked()
        width: 180; height: 32; radius: 10
        color: rowArea.containsMouse ? Theme.tileHover : "transparent"
        Text {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: rowItem.label; color: rowItem.tint
            font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
        }
        MouseArea {
            id: rowArea
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { rowItem.picked(); menu.dock.menuKey = "" }
        }
    }

    Column {
        id: menuColumn
        anchors.centerIn: parent
        MenuRow {
            readonly property string entryId: menu.dock.menuItem && menu.dock.menuItem.entry ? menu.dock.menuItem.entry.id : ""
            visible: entryId !== ""
            label: Ui.isPinned(entryId) ? "Unpin from dock" : "Pin to dock"
            onPicked: Ui.togglePin(entryId)
        }
        MenuRow {
            visible: !!menu.dock.menuItem && !!menu.dock.menuItem.entry
            label: "New window"
            onPicked: menu.dock.menuItem.entry.execute()
        }
        MenuRow {
            readonly property int count: menu.dock.menuItem ? menu.dock.menuItem.wins.length : 0
            visible: count > 0
            label: count > 1 ? "Close " + count + " windows" : "Close window"
            tint: Theme.red
            onPicked: menu.dock.menuItem.wins.forEach(t => Hyprland.dispatch("hl.dsp.window.close({ window = \"address:0x" + t.address + "\" })"))
        }
    }
}
