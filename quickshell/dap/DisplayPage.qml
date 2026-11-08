import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Control Center page: places the external monitor left or right of the laptop.
ColumnLayout {
    id: page
    property string side: "right"
    property bool portrait: false
    signal back()
    signal sidePicked(string side)

    Layout.fillWidth: true; spacing: 8

    readonly property var laptop: Hyprland.monitors.values.find(m => m.name.startsWith("eDP")) ?? null
    readonly property var external: Hyprland.monitors.values.find(m => !m.name.startsWith("eDP")) ?? null
    readonly property string extName: external ? (external.lastIpcObject.model || external.name) : ""

    // Fall back to a 16:9 outline until the compositor has reported sizes.
    readonly property real lapW: laptop ? laptop.width : 1920
    readonly property real lapH: laptop ? laptop.height : 1080
    readonly property real extW: external ? (portrait ? external.height : external.width) : 1920
    readonly property real extH: external ? (portrait ? external.width : external.height) : 1080
    readonly property real gap: 4
    readonly property real k: Math.min((stage.width - 32 - gap) / (lapW + extW), (stage.height - 32) / Math.max(lapH, extH))
    readonly property real startX: (stage.width - (lapW + extW) * k - gap) / 2

    // Live while dragging, so the laptop slides aside before the drop.
    readonly property string shownSide: drag.pressed
        ? (dragX + extW * k / 2 < stage.width / 2 ? "left" : "right")
        : side
    property real dragX: 0

    PageHeader { title: "Displays"; onBack: page.back() }

    Text {
        visible: !page.external
        text: "No external display connected."
        font.family: Theme.font; font.pixelSize: 12; color: Theme.subtext
        Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering
    }

    Rectangle {
        id: stage
        visible: !!page.external
        Layout.fillWidth: true; Layout.preferredHeight: 148
        radius: 14; color: Theme.tile

        component Screen: Rectangle {
            id: screenRect
            property string label: ""
            property bool held: false
            y: (stage.height - height) / 2
            radius: 8
            Behavior on x {
                enabled: !screenRect.held
                NumberAnimation { duration: 240; easing.type: Easing.OutExpo }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: screenRect.label
                font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                color: Theme.text; renderType: Text.NativeRendering
            }
        }

        Screen {
            label: "Laptop"
            width: page.lapW * page.k; height: page.lapH * page.k
            x: page.shownSide === "left" ? page.startX + page.extW * page.k + page.gap : page.startX
            color: Theme.tile
            border.width: 1; border.color: Theme.stroke
        }

        Screen {
            id: ext
            label: page.extName
            held: drag.pressed
            z: 1
            width: page.extW * page.k; height: page.extH * page.k
            x: drag.pressed ? page.dragX : (page.side === "left" ? page.startX : page.startX + page.lapW * page.k + page.gap)
            color: Theme.tileHover
            border.width: drag.pressed ? 2 : 1
            border.color: drag.pressed || drag.containsMouse ? Theme.accent : Theme.stroke

            MouseArea {
                id: drag
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real grabX: 0
                onPressed: mouse => { page.dragX = ext.x; grabX = mouse.x }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const stageX = mapToItem(stage, mouse.x, 0).x
                    page.dragX = Math.max(0, Math.min(stage.width - ext.width, stageX - grabX))
                }
                onReleased: {
                    const next = page.dragX + ext.width / 2 < stage.width / 2 ? "left" : "right"
                    if (next !== page.side) page.sidePicked(next)
                }
            }
        }
    }

    RowLayout {
        visible: !!page.external
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [{ k: "left", g: 0xF004D, t: "Left" }, { k: "right", g: 0xF0054, t: "Right" }]
            delegate: Tile {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredWidth: 1; compact: true
                glyph: Theme.g(modelData.g); title: modelData.t
                on: page.side === modelData.k; onColor: Theme.blue
                onClicked: if (page.side !== modelData.k) page.sidePicked(modelData.k)
            }
        }
    }

    Text {
        visible: !!page.external
        text: page.extName + " sits " + page.side + " of the laptop. Kept after restart."
        font.family: Theme.font; font.pixelSize: 11; color: Theme.subtext
        Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering
    }

    Text {
        text: "TOP BAR"; Layout.topMargin: 6
        font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        color: Theme.subtext; renderType: Text.NativeRendering
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [{ only: false, g: 0xF0379, t: "All displays" }, { only: true, g: 0xF0E7B, t: "Main only" }]
            delegate: Tile {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredWidth: 1; compact: true
                glyph: Theme.g(modelData.g); title: modelData.t
                on: Ui.barMainOnly === modelData.only; onColor: Theme.blue
                onClicked: Ui.setBarMainOnly(modelData.only)
            }
        }
    }

    Text {
        visible: Ui.barMainOnly
        text: "MAIN DISPLAY"; Layout.topMargin: 6
        font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        color: Theme.subtext; renderType: Text.NativeRendering
    }
    Repeater {
        model: Ui.barMainOnly ? Quickshell.screens : []
        delegate: PickRow {
            required property var modelData
            title: Ui.screenLabel(modelData)
            current: Ui.screenKey(modelData) === Ui.barMainKey
            onPicked: Ui.setBarMain(modelData)
        }
    }
}
