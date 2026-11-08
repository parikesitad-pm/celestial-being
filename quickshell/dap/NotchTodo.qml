import QtQuick
import QtQuick.Layouts

// Notch page: a short todo list, saved to ~/.local/state/dap-shell-todo.json.
Item {
    id: page
    // While a task is half-typed the notch stays open, even if the pointer leaves it.
    readonly property bool typing: input.activeFocus && input.text.length > 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            height: 32; radius: 16
            color: Theme.tile
            border.width: 1
            border.color: input.activeFocus ? Theme.accent : "transparent"
            Behavior on border.color { ColorAnimation { duration: 120 } }
            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.onTint
                Keys.onReturnPressed: { Agenda.addTodo(text); text = "" }
                Keys.onEnterPressed: { Agenda.addTodo(text); text = "" }
                Keys.onEscapePressed: { text = ""; focus = false }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Add a task, press Enter"
                    font: input.font
                    color: Theme.subtext
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: Agenda.todos
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width; height: 28; radius: 8
                color: rowArea.containsMouse ? Theme.tile : "transparent"
                MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    spacing: 8
                    Text {
                        text: Theme.g(row.modelData.done ? 0xF0132 : 0xF0131)
                        font.family: Theme.iconFont; font.pixelSize: 15
                        color: row.modelData.done ? Theme.accent : Theme.subtext
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Agenda.toggleTodo(row.index) }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.text
                        elide: Text.ElideRight
                        font.family: Theme.font; font.pixelSize: 12
                        font.strikeout: row.modelData.done
                        color: row.modelData.done ? Theme.subtext : Theme.text
                    }
                    Text {
                        visible: rowArea.containsMouse
                        text: Theme.g(0xF0156)
                        font.family: Theme.iconFont; font.pixelSize: 13
                        color: Theme.subtext
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Agenda.removeTodo(row.index) }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "No tasks yet."
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.subtext
            }
        }
    }
}
