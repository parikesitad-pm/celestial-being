import QtQuick
import "../atoms"

Item {
    id: bar

    property var sessions
    property int sessionIndex: 0
    property bool canReboot: true
    property bool canPowerOff: true

    signal rebootRequested()
    signal powerOffRequested()

    implicitHeight: 36

    Repeater {
        id: sessionNames
        model: bar.sessions
        Item { required property string name; readonly property string label: name }
    }

    FocusScope {
        id: sessionButton
        readonly property bool switchable: sessionNames.count > 1
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: sessionLabel.implicitWidth + 24
        height: 36
        activeFocusOnTab: switchable
        Accessible.role: Accessible.Button
        Accessible.name: "Session: " + sessionLabel.text

        function next() {
            if (switchable)
                bar.sessionIndex = (bar.sessionIndex + 1) % sessionNames.count
        }

        Keys.onReturnPressed: next()
        Keys.onEnterPressed: next()
        Keys.onSpacePressed: next()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: sessionPointer.containsMouse ? "#1fe8f1ff" : "transparent"
            border.width: sessionButton.activeFocus ? 2 : 0
            border.color: Tokens.green
        }
        Text {
            id: sessionLabel
            anchors.centerIn: parent
            // itemAt() is not reactive; reading count re-evaluates this once the Repeater fills.
            text: sessionNames.count > bar.sessionIndex ? sessionNames.itemAt(bar.sessionIndex).label : ""
            color: Tokens.ink
            opacity: sessionPointer.containsMouse || sessionButton.activeFocus ? 1 : 0.65
            font { family: Tokens.mono; pixelSize: 12 }
        }
        MouseArea {
            id: sessionPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: sessionButton.switchable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: sessionButton.next()
        }
    }

    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 8
        IconButton {
            visible: bar.canReboot
            glyph: ""
            name: "Reboot"
            onActivated: bar.rebootRequested()
        }
        IconButton {
            visible: bar.canPowerOff
            glyph: ""
            name: "Power off"
            onActivated: bar.powerOffRequested()
        }
    }
}
