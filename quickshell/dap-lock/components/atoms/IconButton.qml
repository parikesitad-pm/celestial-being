import QtQuick
import "."

FocusScope {
    id: button

    property alias glyph: label.text
    property string name
    signal activated()

    width: 36
    height: 36
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: name
    Accessible.onPressAction: activated()

    Keys.onReturnPressed: activated()
    Keys.onEnterPressed: activated()
    Keys.onSpacePressed: activated()

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: pointer.pressed ? "#33e8f1ff" : pointer.containsMouse ? "#1fe8f1ff" : "transparent"
        border.width: button.activeFocus ? 2 : 0
        border.color: Tokens.green
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: Tokens.ink
        opacity: pointer.containsMouse || button.activeFocus ? 1 : 0.65
        font { family: Tokens.mono; pixelSize: 16 }
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.activated()
    }
}
