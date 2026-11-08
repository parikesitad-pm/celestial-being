import QtQuick
import QtQuick.Layouts
import Quickshell

// Hangar tab: every app, with search. Type to filter, Enter launches the selected app, arrows move.
// The island opens extra wide on this tab, since it holds only apps.
ColumnLayout {
    id: page
    property bool shown: false
    property string query: ""
    property int sel: 0
    spacing: 10

    onShownChanged: if (shown) { query = ""; input.text = ""; sel = 0; input.forceActiveFocus() }

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
    function launch(e) { if (!e) return; Ui.island = false; e.execute() }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: 18
        color: Theme.tile
        border.width: 1
        border.color: input.activeFocus ? Theme.accent : Theme.stroke
        Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: Theme.g(0xF0349)
            font.family: Theme.iconFont; font.pixelSize: 15
            color: Theme.subtext
        }
        TextInput {
            id: input
            anchors { left: parent.left; leftMargin: 40; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            font.family: Theme.font; font.pixelSize: 13
            color: Theme.text
            onTextChanged: page.query = text
            Keys.onReturnPressed: page.launch(page.results[page.sel])
            Keys.onRightPressed: page.sel = Math.min(page.results.length - 1, page.sel + 1)
            Keys.onLeftPressed: page.sel = Math.max(0, page.sel - 1)
            Keys.onDownPressed: page.sel = Math.min(page.results.length - 1, page.sel + grid.columns)
            Keys.onUpPressed: page.sel = Math.max(0, page.sel - grid.columns)
            Text {
                visible: !input.text
                text: "Search apps"
                font: input.font
                color: Theme.subtext
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        readonly property int columns: Math.max(1, Math.floor(width / 104))
        cellWidth: width / columns
        cellHeight: 96
        model: page.results
        currentIndex: page.sel
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool current: page.sel === index
            width: grid.cellWidth; height: grid.cellHeight
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 16
                color: cell.current ? Theme.tileHover : (area.containsMouse ? Theme.tile : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Column {
                anchors.centerIn: parent
                spacing: 6
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 40; height: 40
                    source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                    sourceSize: Qt.size(80, 80)
                    smooth: true; mipmap: true
                    asynchronous: true
                    scale: area.pressed ? 0.9 : (area.containsMouse ? 1.1 : 1)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }
                }
                Text {
                    width: grid.cellWidth - 12
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: cell.modelData.name
                    font.family: Theme.font; font.pixelSize: 11
                    color: cell.current ? Theme.text : Theme.subtext
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.launch(cell.modelData)
            }
        }
    }

    Text {
        visible: page.results.length === 0
        Layout.alignment: Qt.AlignHCenter
        text: "No apps match “" + page.query.trim() + "”"
        font.family: Theme.font; font.pixelSize: 12
        color: Theme.subtext
    }
}
