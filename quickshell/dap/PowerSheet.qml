import QtQuick
import QtQuick.Layouts

// Session sheet in the island, opened by the side bar's power button. Lock runs at once;
// Logout, Restart and Shutdown ask for a second, explicit confirm. Esc or Cancel backs out.
ColumnLayout {
    id: sheet
    property string armed: ""
    readonly property var actions: [
        { k: "lock",     t: "Lock",     g: 0xF033E, c: Theme.scripts + "lock.sh" },
        { k: "logout",   t: "Logout",   g: 0xF08B,  c: "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
        { k: "reboot",   t: "Restart",  g: 0xF021,  c: "systemctl reboot" },
        { k: "poweroff", t: "Shutdown", g: 0xF011,  c: "systemctl poweroff" }
    ]
    readonly property var picked: actions.find(a => a.k === armed) || null
    function run(a) { armed = ""; Ui.island = false; Ui.sh(a.c) }
    spacing: 14

    focus: visible
    onVisibleChanged: armed = ""
    Keys.onEscapePressed: event => {
        if (armed !== "") { armed = ""; event.accepted = true }
        else event.accepted = false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: sheet.actions
            delegate: Rectangle {
                id: tile
                required property var modelData
                readonly property bool on: sheet.armed === modelData.k
                readonly property bool dim: sheet.armed !== "" && !on
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 20
                color: on ? Theme.transAmRed : (area.containsMouse ? Theme.tileHover : Theme.tile)
                opacity: dim ? 0.4 : 1
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
                scale: area.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.g(tile.modelData.g)
                        font.family: Theme.iconFont; font.pixelSize: 26
                        color: tile.on ? Theme.onTint : (tile.modelData.k === "poweroff" ? Theme.transAmRed : Theme.text)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.t
                        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                        color: tile.on ? Theme.onTint : Theme.text
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.modelData.k === "lock" ? sheet.run(tile.modelData) : (sheet.armed = tile.on ? "" : tile.modelData.k)
                }
            }
        }
    }

    // Confirm strip: caution tape and the explicit action.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        opacity: sheet.picked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        HazardStripe { Layout.fillWidth: true; Layout.preferredHeight: 6; running: parent.visible; color: Theme.transAmRed }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.fillWidth: true
                text: sheet.picked ? sheet.picked.t + " now? Unsaved work in open apps will be lost." : ""
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.text
                elide: Text.ElideRight
            }
            Rectangle {
                Layout.preferredWidth: 88; Layout.preferredHeight: 34; radius: 17
                color: cancelArea.containsMouse ? Theme.tileHover : Theme.tile
                Text { anchors.centerIn: parent; text: "Cancel"; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.text }
                MouseArea { id: cancelArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sheet.armed = "" }
            }
            Rectangle {
                Layout.preferredWidth: 120; Layout.preferredHeight: 34; radius: 17
                color: Theme.transAmRed
                Text { anchors.centerIn: parent; text: sheet.picked ? sheet.picked.t : ""; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.onTint }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (sheet.picked) sheet.run(sheet.picked) }
            }
        }
    }
}
