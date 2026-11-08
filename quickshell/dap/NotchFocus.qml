import QtQuick
import QtQuick.Layouts

// Notch page: a focus (pomodoro) countdown. The pill keeps counting while the notch is closed.
Item {
    id: page
    readonly property bool running: Agenda.focusEnd > 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Ui.mmss(page.running ? Agenda.focusLeft : Agenda.focusMinutes * 60)
            font.family: Theme.font; font.pixelSize: 42; font.weight: Font.Bold
            color: page.running ? Theme.accent : Theme.text
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: page.running ? "Focus · ends " + Qt.formatDateTime(new Date(Agenda.focusEnd), "HH:mm") : "Pick a length"
            font.family: Theme.font; font.pixelSize: 12
            color: Theme.subtext
        }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            opacity: page.running ? 0.4 : 1
            Repeater {
                model: [15, 25, 45, 60]
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool current: Agenda.focusMinutes === modelData
                    width: 44; height: 24; radius: 12
                    color: current ? Theme.tileHover : (lenArea.containsMouse ? Theme.tile : "transparent")
                    border.width: 1; border.color: Theme.stroke
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData + "m"
                        font.family: Theme.font; font.pixelSize: 11; font.weight: current ? Font.Bold : Font.Normal
                        color: current ? Theme.text : Theme.subtext
                    }
                    MouseArea {
                        id: lenArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !page.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Agenda.focusMinutes = modelData
                    }
                }
            }
        }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 128; height: 34; radius: 17
            color: page.running ? Theme.tile : Theme.accent
            scale: goArea.pressed ? 0.95 : 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: Theme.g(page.running ? 0xF04DB : 0xF040A)
                    font.family: Theme.iconFont; font.pixelSize: 15
                    color: page.running ? Theme.text : Theme.onTint
                }
                Text {
                    text: page.running ? "Stop" : "Start"
                    font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                    color: page.running ? Theme.text : Theme.onTint
                }
            }
            MouseArea {
                id: goArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: page.running ? Agenda.focusStop() : Agenda.focusStart()
            }
        }
    }
}
