import QtQuick

// Small rounded text field with a placeholder; Enter emits `submitted`.
Rectangle {
    id: f
    property alias input: field
    property string hint: ""
    signal submitted
    height: 28; radius: 14
    color: Theme.tile
    border.width: 1; border.color: field.activeFocus ? Theme.accent : "transparent"

    TextInput {
        id: field
        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        font.family: Theme.font; font.pixelSize: 11
        color: Theme.text
        selectionColor: Theme.accent; selectedTextColor: Theme.onTint
        Keys.onReturnPressed: f.submitted()
        Keys.onEnterPressed: f.submitted()
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: field.text === ""
            text: f.hint
            font: field.font
            color: Theme.subtext
        }
    }
}
