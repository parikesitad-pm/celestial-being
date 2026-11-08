import QtQuick
import QtQuick.Layouts

// Widened island showing the newest notification for a few seconds.
RowLayout {
    id: toast
    property var notif: null
    spacing: 12

    Item {
        Layout.preferredWidth: 36; Layout.preferredHeight: 36
        Image {
            id: icon
            anchors.fill: parent
            source: toast.notif ? Ui.iconSource(toast.notif.icon) : ""
            sourceSize: Qt.size(72, 72)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Theme.tile
            visible: icon.status !== Image.Ready
            Text {
                anchors.centerIn: parent
                text: Theme.g(0xF009A)
                font.family: Theme.iconFont; font.pixelSize: 17
                color: Theme.accent
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            Layout.fillWidth: true
            text: toast.notif ? (toast.notif.summary || toast.notif.app) : ""
            elide: Text.ElideRight
            font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: toast.notif ? (toast.notif.body || "").replace(/\s+/g, " ") : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.family: Theme.font; font.pixelSize: 12
            color: Theme.subtext
        }
    }

    Text {
        visible: actionRow.count === 0
        text: toast.notif ? toast.notif.app : ""
        font.family: Theme.font; font.pixelSize: 10
        color: Theme.subtext
    }

    // The sender's buttons (Answer / Decline on a call, Reply, …); "default" is the body click.
    Row {
        spacing: 6
        Repeater {
            id: actionRow
            model: toast.notif ? toast.notif.actions.filter(a => a.identifier !== "default" && a.text) : []
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: label.implicitWidth + 20; height: 28; radius: 14
                color: index === 0 ? Theme.accent : (area.containsMouse ? Theme.tileHover : Theme.tile)
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData.text
                    font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
                    color: index === 0 ? Theme.onTint : Theme.text
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Ui.invokeAction(toast.notif, modelData)
                }
            }
        }
    }
}
