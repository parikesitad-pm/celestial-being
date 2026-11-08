import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: Ui.launcher || card.opacity > 0.01
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.launcher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int sel: 0

    readonly property var results: {
        const q = query.trim().toLowerCase()
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        if (q === "") return all.sort((a, b) => a.name.localeCompare(b.name))
        const scored = []
        for (const e of all) {
            const n = e.name.toLowerCase()
            let s = -1
            if (n.startsWith(q)) s = 100
            else if (n.includes(" " + q)) s = 80
            else if (n.includes(q)) s = 60
            else if ((e.genericName || "").toLowerCase().includes(q) || (e.comment || "").toLowerCase().includes(q)) s = 30
            else if ((e.keywords || []).join(" ").toLowerCase().includes(q)) s = 20
            if (s >= 0) scored.push({ e: e, s: s })
        }
        return scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name)).map(x => x.e)
    }
    onResultsChanged: { sel = 0; grid.positionViewAtBeginning() }

    Connections { target: Ui; function onLauncherChanged() { if (Ui.launcher) { win.query = ""; win.sel = 0; input.text = ""; input.forceActiveFocus() } } }

    function launch(e) { if (!e) return; Ui.launcher = false; e.execute() }
    function iconSrc(i) { return !i ? Quickshell.iconPath("application-x-executable") : (i.startsWith("/") ? "file://" + i : Quickshell.iconPath(i, "application-x-executable")) }
    // Keyboard only: scrolling on hover would move the tile out from under the pointer.
    function moveSel(by) {
        if (win.results.length === 0) return
        sel = Math.max(0, Math.min(sel + by, win.results.length - 1))
        grid.positionViewAtIndex(sel, GridView.Contain)
    }

    MouseArea { anchors.fill: parent; onClicked: Ui.launcher = false }

    Rectangle {
        id: card
        readonly property int columns: 6
        width: Math.min(900, parent.width - 48)
        height: Math.min(640, parent.height - 120)
        anchors.centerIn: parent
        radius: 28
        color: Theme.glassStrong
        border.width: 1; border.color: Theme.stroke
        opacity: Ui.launcher ? 1 : 0
        scale: Ui.launcher ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Ui.launcher ? 180 : 120; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Ui.launcher ? 240 : 140; easing.type: Easing.OutExpo } }
        MouseArea { anchors.fill: parent }   // swallow clicks

        // search field
        Item {
            id: bar
            x: 20; y: 14; width: parent.width - 40; height: 56
            Text { id: mag; x: 6; anchors.verticalCenter: parent.verticalCenter; text: Theme.g(0xF0349); font.family: Theme.iconFont; font.pixelSize: 24; color: Theme.accent }
            TextInput {
                id: input
                anchors { left: mag.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
                font.family: Theme.font; font.pixelSize: 24; color: Theme.text
                selectionColor: Theme.accent; selectedTextColor: Theme.onTint
                clip: true
                onTextChanged: win.query = text
                Keys.onEscapePressed: Ui.launcher = false
                Keys.onRightPressed: win.moveSel(1)
                Keys.onLeftPressed: win.moveSel(-1)
                Keys.onDownPressed: win.moveSel(card.columns)
                Keys.onUpPressed: win.moveSel(-card.columns)
                Keys.onTabPressed: win.moveSel(1)
                Keys.onReturnPressed: win.launch(win.results[win.sel])
                Keys.onEnterPressed: win.launch(win.results[win.sel])
                Text { visible: !input.text; text: "Search apps…"; font: input.font; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        Rectangle { x: 20; y: 78; width: parent.width - 40; height: 1; color: Theme.stroke }

        Text {
            anchors.centerIn: grid
            visible: win.results.length === 0
            width: grid.width - 48
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: "No apps match \u201C" + win.query.trim() + "\u201D"
            font.family: Theme.font; font.pixelSize: 16; color: Theme.subtext
        }

        GridView {
            id: grid
            x: 12; y: 88; width: parent.width - 24; height: parent.height - 100
            model: win.results
            clip: true
            cellWidth: Math.floor(width / card.columns); cellHeight: 124
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 124
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool selected: index === win.sel
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle {
                    anchors { fill: parent; margins: 4 }
                    radius: 16
                    color: cell.selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) : "transparent"
                    border.width: cell.selected ? 1 : 0
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                }
                Image {
                    x: (parent.width - width) / 2; y: 12
                    width: 60; height: 60; sourceSize: Qt.size(60, 60)
                    smooth: true; asynchronous: true
                    source: win.iconSrc(cell.modelData.icon)
                }
                Text {
                    x: 10; y: 78; width: parent.width - 20
                    text: cell.modelData.name
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.text
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true
                    onPositionChanged: win.sel = cell.index
                    onClicked: win.launch(cell.modelData) }
                // pin toggle: always shown when pinned, otherwise on the selected tile
                Item {
                    readonly property bool pinned: Ui.isPinned(cell.modelData.id)
                    visible: pinned || cell.selected
                    anchors { right: parent.right; rightMargin: 8; top: parent.top; topMargin: 8 }
                    width: 28; height: 28
                    Text {
                        anchors.centerIn: parent
                        text: Theme.g(parent.pinned ? 0xF0403 : 0xF0931)
                        color: parent.pinned ? Theme.accent : Theme.subtext
                        font.family: Theme.iconFont; font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPositionChanged: win.sel = cell.index
                        onClicked: Ui.togglePin(cell.modelData.id)
                    }
                }
            }
        }
        // scroll position, shown only when the list overflows
        Rectangle {
            visible: grid.visibleArea.heightRatio < 1
            x: card.width - 8; y: grid.y + grid.visibleArea.yPosition * grid.height
            width: 3; height: grid.visibleArea.heightRatio * grid.height; radius: 2
            color: Theme.stroke
        }
    }
}
