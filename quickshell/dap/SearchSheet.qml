import QtQuick
import QtQuick.Layouts
import Quickshell

// Super+Space: the island opens as one search line; results appear below only once you type.
// Enter launches the highlighted app, Up/Down move, Esc closes.
ColumnLayout {
    id: page
    property bool shown: false
    property string query: ""
    property int sel: 0
    readonly property int maxRows: 7
    readonly property var results: query.trim() === "" ? [] : Apps.search(query).slice(0, maxRows)
    spacing: 6

    onShownChanged: if (shown) { query = ""; input.text = ""; sel = 0; input.forceActiveFocus() }
    onResultsChanged: sel = 0
    function launch(e) { if (!e) return; Ui.island = false; e.execute() }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        spacing: 12
        Text {
            text: Theme.g(0xF0349)
            font.family: Theme.iconFont; font.pixelSize: 18
            color: Theme.accent
        }
        TextInput {
            id: input
            Layout.fillWidth: true
            font.family: Theme.font; font.pixelSize: 16
            color: Theme.text
            onTextChanged: page.query = text
            Keys.onReturnPressed: page.launch(page.results[page.sel])
            Keys.onDownPressed: page.sel = Math.min(page.results.length - 1, page.sel + 1)
            Keys.onUpPressed: page.sel = Math.max(0, page.sel - 1)
            Text {
                visible: !input.text
                text: "Search apps"
                font: input.font
                color: Theme.subtext
            }
        }
        Text {
            visible: page.results.length > 0
            text: "↵ launch"
            font.family: Theme.font; font.pixelSize: 11
            color: Theme.subtext
        }
    }

    Repeater {
        model: page.results
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: page.sel === index
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 12
            color: current ? Theme.tileHover : (area.containsMouse ? Theme.tile : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 12
                Image {
                    Layout.preferredWidth: 26; Layout.preferredHeight: 26
                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    sourceSize: Qt.size(52, 52)
                    smooth: true; mipmap: true
                    asynchronous: true
                }
                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                    font.family: Theme.font; font.pixelSize: 13; font.weight: row.current ? Font.Bold : Font.Normal
                    color: Theme.text
                }
                Text {
                    text: row.modelData.genericName || ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    Layout.maximumWidth: 200
                    font.family: Theme.font; font.pixelSize: 11
                    color: Theme.subtext
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.launch(row.modelData)
            }
        }
    }

    Text {
        visible: page.query.trim() !== "" && page.results.length === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 4
        text: "No apps match “" + page.query.trim() + "”"
        font.family: Theme.font; font.pixelSize: 12
        color: Theme.subtext
    }
}
