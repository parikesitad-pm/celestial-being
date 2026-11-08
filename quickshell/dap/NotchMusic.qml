import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Notch page: cover, track, source switcher, audio bars, progress and transport controls.
Item {
    id: page
    property bool active: false
    readonly property var player: Ui.player

    // Mpris position is not pushed by the player; ask for it while this page is showing.
    Timer {
        interval: 1000
        repeat: true
        running: page.active && !!page.player && page.player.isPlaying
        onTriggered: page.player.positionChanged()
    }

    component Control: Rectangle {
        id: ctl
        property int glyph
        property bool primary: false
        signal pressed
        width: primary ? 36 : 30; height: width; radius: width / 2
        color: primary ? Theme.accent : (ctlArea.containsMouse ? Theme.tileHover : Theme.tile)
        scale: ctlArea.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: Theme.g(ctl.glyph)
            font.family: Theme.iconFont
            font.pixelSize: ctl.primary ? 18 : 15
            color: ctl.primary ? Theme.onTint : Theme.text
        }
        MouseArea {
            id: ctlArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.pressed()
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !page.player
        text: "Nothing playing"
        font.family: Theme.font; font.pixelSize: 13
        color: Theme.subtext
    }

    RowLayout {
        anchors.fill: parent
        visible: !!page.player
        spacing: 14

        Item {
            Layout.preferredWidth: 120; Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignVCenter
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Theme.tile
                visible: art.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: Theme.g(0xF075A)
                    font.family: Theme.iconFont; font.pixelSize: 40
                    color: Theme.subtext
                }
            }
            Image {
                id: art
                anchors.fill: parent
                source: page.player ? page.player.trackArtUrl : ""
                sourceSize: Qt.size(240, 240)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: artMask; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: art
                source: art
                visible: art.status === Image.Ready
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            Text {
                Layout.fillWidth: true
                text: page.player ? (page.player.trackTitle || "Unknown title") : ""
                elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Bold
                color: Theme.text
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: page.player ? page.player.trackArtist : ""
                elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.subtext
            }
            // One chip per source; the highlighted one is what the pill and controls follow.
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: Ui.players
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool current: modelData === Ui.player
                        width: chip.implicitWidth + 14; height: 18; radius: 9
                        color: current ? Theme.accent : (chipArea.containsMouse ? Theme.tileHover : Theme.tile)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: chip
                            anchors.centerIn: parent
                            text: modelData.identity
                            font.family: Theme.font; font.pixelSize: 10; font.weight: Font.DemiBold
                            color: current ? Theme.onTint : Theme.subtext
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Ui.picked = modelData
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            CavaBars {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                running: page.active && !!page.player && page.player.isPlaying
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !!page.player && page.player.lengthSupported && page.player.length > 0
                Text { text: Ui.mmss(page.player ? page.player.position : 0); font.family: Theme.font; font.pixelSize: 10; color: Theme.subtext }
                Rectangle {
                    Layout.fillWidth: true
                    height: 4; radius: 2
                    color: Theme.tile
                    Rectangle {
                        height: parent.height; radius: 2
                        color: Theme.accent
                        width: page.player && page.player.length > 0
                               ? parent.width * Math.min(1, page.player.position / page.player.length) : 0
                    }
                }
                Text { text: Ui.mmss(page.player ? page.player.length : 0); font.family: Theme.font; font.pixelSize: 10; color: Theme.subtext }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Control {
                    glyph: 0xF04AE
                    opacity: page.player && page.player.canGoPrevious ? 1 : 0.4
                    onPressed: if (page.player && page.player.canGoPrevious) page.player.previous()
                }
                Control {
                    primary: true
                    glyph: page.player && page.player.isPlaying ? 0xF03E4 : 0xF040A
                    onPressed: if (page.player && page.player.canTogglePlaying) page.player.togglePlaying()
                }
                Control {
                    glyph: 0xF04AD
                    opacity: page.player && page.player.canGoNext ? 1 : 0.4
                    onPressed: if (page.player && page.player.canGoNext) page.player.next()
                }
            }
        }
    }
}
