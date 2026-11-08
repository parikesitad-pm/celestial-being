import QtQuick
import QtQuick.Layouts

// Island page: the month on the left (a dot marks busy days), the picked day's Google Calendar
// events and alarms on the right, with a row to set a new alarm on that day.
Item {
    id: page
    property bool shown: false
    property date view: new Date(Ui.now.getFullYear(), Ui.now.getMonth(), 1)
    property date picked: new Date(Ui.now.getFullYear(), Ui.now.getMonth(), Ui.now.getDate())
    property string error: ""
    onShownChanged: if (shown) {
        view = new Date(Ui.now.getFullYear(), Ui.now.getMonth(), 1)
        picked = new Date(Ui.now.getFullYear(), Ui.now.getMonth(), Ui.now.getDate())
    }
    function shift(n) { view = new Date(view.getFullYear(), view.getMonth() + n, 1) }
    function sameDay(x, y) { return x.getFullYear() === y.getFullYear() && x.getMonth() === y.getMonth() && x.getDate() === y.getDate() }
    function add() {
        const t = timeField.input, l = labelField.input
        if (Agenda.addAlarm(page.picked, t.text, l.text)) { t.text = ""; l.text = ""; error = "" }
        else error = "Use HH:MM, later than now"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 236
            Layout.fillHeight: true
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: Qt.formatDateTime(page.view, "MMMM yyyy"); font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.text }
                Repeater {
                    model: [{ g: "‹", n: -1 }, { g: "›", n: 1 }]
                    delegate: Rectangle {
                        required property var modelData
                        width: 22; height: 22; radius: 11
                        color: navArea.containsMouse ? Theme.tileHover : Theme.tile
                        Text { anchors.centerIn: parent; text: modelData.g; font.family: Theme.font; font.pixelSize: 14; color: Theme.text }
                        MouseArea { id: navArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.shift(modelData.n) }
                    }
                }
            }
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7; columnSpacing: 0; rowSpacing: 0
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: Theme.font; font.pixelSize: 9; font.weight: Font.DemiBold
                        color: Theme.subtext
                    }
                }
                Repeater {
                    model: Agenda.monthGrid(page.view, Ui.now)
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool isPicked: page.sameDay(modelData.date, page.picked)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: 22; height: 22; radius: 11
                            color: cell.modelData.today ? Theme.accent : (dayArea.containsMouse ? Theme.tile : "transparent")
                            border.width: cell.isPicked ? 1.5 : 0
                            border.color: cell.modelData.today ? Theme.text : Theme.accent
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData.d
                            font.family: Theme.font; font.pixelSize: 10
                            font.weight: cell.modelData.today ? Font.Bold : Font.Normal
                            color: cell.modelData.today ? Theme.onTint
                                 : (cell.modelData.cur ? ((cell.index % 7) >= 5 ? Theme.orange : Theme.text) : Theme.subtext)
                            opacity: cell.modelData.cur ? 1 : 0.4
                        }
                        // Busy day: something on Google Calendar or an alarm.
                        Rectangle {
                            visible: Agenda.busy(cell.modelData.date)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 4; height: 4; radius: 2
                            color: Theme.gold
                        }
                        MouseArea { id: dayArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.picked = cell.modelData.date }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Text {
                text: Qt.formatDateTime(page.picked, "dddd, d MMMM")
                font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                color: Theme.text
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: Agenda.itemsOn(page.picked)
                delegate: Rectangle {
                    id: item
                    required property var modelData
                    width: list.width; height: 24; radius: 8
                    color: itemHover.hovered ? Theme.tile : "transparent"
                    HoverHandler { id: itemHover }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                        spacing: 6
                        Text {
                            Layout.preferredWidth: 40
                            text: item.modelData.allDay ? "all day" : Qt.formatDateTime(new Date(item.modelData.time), "HH:mm")
                            font.family: Theme.font; font.pixelSize: 10
                            color: Theme.subtext
                        }
                        Text {
                            text: item.modelData.kind === "alarm" ? Theme.g(0xF009A) : "●"
                            font.family: Theme.iconFont; font.pixelSize: item.modelData.kind === "alarm" ? 12 : 8
                            color: item.modelData.kind === "alarm" ? Theme.gold : Theme.blue
                        }
                        Text {
                            Layout.fillWidth: true
                            text: item.modelData.title
                            elide: Text.ElideRight
                            font.family: Theme.font; font.pixelSize: 11
                            color: Theme.text
                        }
                        Text {
                            visible: item.modelData.kind === "alarm" && itemHover.hovered
                            text: Theme.g(0xF0156)
                            font.family: Theme.iconFont; font.pixelSize: 12
                            color: Theme.subtext
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Agenda.removeAlarm(item.modelData.at) }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "Nothing planned."
                    font.family: Theme.font; font.pixelSize: 11
                    color: Theme.subtext
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                PillField { id: timeField; Layout.preferredWidth: 62; hint: "07:30"; onSubmitted: page.add() }
                PillField { id: labelField; Layout.fillWidth: true; hint: "Label"; onSubmitted: page.add() }
                Rectangle {
                    width: addText.implicitWidth + 18; height: 28; radius: 14
                    color: addArea.containsMouse ? Theme.accent : Theme.tileHover
                    Text {
                        id: addText
                        anchors.centerIn: parent
                        text: "+ Alarm"
                        font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
                        color: addArea.containsMouse ? Theme.onTint : Theme.text
                    }
                    MouseArea { id: addArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.add() }
                }
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: 9
                color: page.error !== "" || Agenda.calStatus === "error" ? Theme.red : Theme.subtext
                text: page.error !== "" ? page.error
                    : Agenda.calStatus === "ok" ? "Google Calendar linked"
                    : Agenda.calStatus === "error" ? "Google Calendar: couldn't fetch the feed"
                    : "Google Calendar: not linked yet"
            }
        }
    }

}
