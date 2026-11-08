import QtQuick
import QtQuick.Layouts

// Island page: notifications received since the shell started, newest first.
Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Ui.notifs.length + (Ui.notifs.length === 1 ? " notification" : " notifications")
                font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                color: Theme.subtext
            }
            Rectangle {
                visible: Ui.notifs.length > 0
                width: clearText.implicitWidth + 20; height: 22; radius: 11
                color: clearArea.containsMouse ? Theme.tileHover : Theme.tile
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear"
                    font.family: Theme.font; font.pixelSize: 11
                    color: Theme.text
                }
                MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.clearNotifs() }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: Ui.notifs
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var buttons: (row.modelData.actions || []).filter(a => a.identifier !== "default" && a.text)
                width: list.width
                height: (body.visible ? 52 : 36) + (buttons.length > 0 ? 30 : 0)
                radius: 12
                color: rowHover.hovered ? Theme.tileHover : Theme.tile
                HoverHandler { id: rowHover }

                Text {
                    anchors.right: parent.right; anchors.top: parent.top
                    anchors.rightMargin: 8; anchors.topMargin: 6
                    z: 1
                    visible: rowHover.hovered
                    text: Theme.g(0xF0156)
                    font.family: Theme.iconFont; font.pixelSize: 13
                    color: Theme.subtext
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Ui.dismissNotif(row.modelData) }
                }
                Row {
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                    anchors.leftMargin: 42; anchors.bottomMargin: 8
                    spacing: 6
                    visible: row.buttons.length > 0
                    Repeater {
                        model: row.buttons
                        delegate: Rectangle {
                            required property var modelData
                            width: actText.implicitWidth + 18; height: 22; radius: 11
                            color: actArea.containsMouse ? Theme.accent : Theme.tileHover
                            Text {
                                id: actText
                                anchors.centerIn: parent
                                text: modelData.text
                                font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                                color: actArea.containsMouse ? Theme.onTint : Theme.text
                            }
                            MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.invokeAction(row.modelData, modelData) }
                        }
                    }
                }

                Image {
                    id: icon
                    x: 8; y: (body.visible ? 52 : 36) / 2 - height / 2
                    width: 24; height: 24
                    source: Ui.iconSource(row.modelData.icon)
                    sourceSize: Qt.size(48, 48)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: icon
                    visible: icon.status !== Image.Ready
                    text: Theme.g(0xF009A)
                    font.family: Theme.iconFont; font.pixelSize: 15
                    color: Theme.subtext
                }
                ColumnLayout {
                    anchors.left: icon.right; anchors.leftMargin: 10
                    anchors.right: parent.right; anchors.rightMargin: 28
                    anchors.top: parent.top
                    anchors.topMargin: body.visible ? 8 : 9
                    spacing: 1
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.summary || row.modelData.app
                            elide: Text.ElideRight
                            font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Bold
                            color: Theme.text
                        }
                        Text {
                            text: row.modelData.app + " · " + Qt.formatDateTime(row.modelData.time, "HH:mm")
                            font.family: Theme.font; font.pixelSize: 10
                            color: Theme.subtext
                        }
                    }
                    Text {
                        id: body
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: (row.modelData.body || "").replace(/\s+/g, " ")
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.family: Theme.font; font.pixelSize: 11
                        color: Theme.subtext
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "No notifications."
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.subtext
            }
        }
    }
}
