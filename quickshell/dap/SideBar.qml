import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth

// Vertical bar on the left edge, top to bottom: emblem (launcher), desktops, apps (the dock),
// desktop name, tray, status, power. Status (gear) opens the Bridge sheet, power the Launch Bay.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { left: true; top: true; bottom: true }
    margins { left: 6; top: 6; bottom: 6 }
    implicitWidth: 48
    exclusiveZone: 54
    color: "transparent"
    WlrLayershell.namespace: "dap-bar"

    readonly property var mon: Hyprland.monitorFor(screen)
    readonly property int activeId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : 0

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property bool muted: !audio || audio.muted

    // Right-click menu for an app (DockMenu): pin, new window, close.
    property string menuKey: ""
    property real menuY: 0
    readonly property var menuItem: Apps.byKey[menuKey] || null
    PopupWindow {
        id: menuPopup
        anchor.window: bar
        anchor.rect.x: bar.width + 8
        anchor.rect.y: Math.max(0, bar.menuY - implicitHeight / 2)
        implicitWidth: menu.width
        implicitHeight: menu.height
        visible: bar.menuKey !== ""
        color: "transparent"
        DockMenu { id: menu; dock: bar }
    }
    HyprlandFocusGrab { windows: [menuPopup]; active: bar.menuKey !== ""; onCleared: bar.menuKey = "" }

    component Sep: Rectangle { Layout.alignment: Qt.AlignHCenter; implicitWidth: 20; implicitHeight: 1; color: Theme.stroke }
    component Glyph: Text {
        Layout.alignment: Qt.AlignHCenter
        font.family: Theme.iconFont; font.pixelSize: 16
        color: Theme.text
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Theme.glass
        border.width: 1
        border.color: Theme.stroke

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 10

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 26; Layout.preferredHeight: 26
                source: "file://" + Theme.assets + "cb-64.png"
                sourceSize: Qt.size(64, 64)
                smooth: true; mipmap: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }

            // This screen's desktops; the active one stretches.
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === bar.mon).sort((a, b) => a.id - b.id)
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: bar.activeId === modelData.id
                        readonly property bool used: modelData.toplevels.values.length > 0
                        width: 8
                        height: active ? 24 : 8
                        radius: 4
                        color: active ? Ui.deskColor(modelData.id) : (used ? Theme.subtext : Theme.tile)
                        Behavior on height { SpringAnimation { spring: 5; damping: 0.45; epsilon: 0.2 } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Ui.workspace(parent.modelData.id)
                        }
                    }
                }
            }

            Sep {}

            // Apps: pinned first, then the other running ones. Left click focuses or launches,
            // middle click opens a new one, right click opens the menu (pin, new window, close).
            ListView {
                id: apps
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 36
                Layout.fillHeight: true
                Layout.maximumHeight: contentHeight
                spacing: 6
                clip: true
                interactive: contentHeight > height
                model: ScriptModel { values: Apps.items.filter(it => !it.isLauncher).map(it => it.key) }
                delegate: Item {
                    id: app
                    required property string modelData
                    readonly property var it: Apps.byKey[modelData] || ({ entry: null, wins: [], cls: "" })
                    readonly property bool focused: !!Hyprland.activeToplevel && it.wins.some(t => t === Hyprland.activeToplevel)
                    width: 36; height: 36
                    // Running mark on the bar's inner edge: short when open, long when focused.
                    Rectangle {
                        x: -6; anchors.verticalCenter: parent.verticalCenter
                        width: 3; radius: 1.5
                        height: app.focused ? 18 : (app.it.wins.length > 0 ? 6 : 0)
                        color: Theme.accent
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    }
                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: 26; height: 26
                        source: Quickshell.iconPath(app.it.entry ? app.it.entry.icon : app.it.cls.toLowerCase(), "application-x-executable")
                        sourceSize: Qt.size(52, 52)
                        smooth: true; mipmap: true
                        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.15 : 1)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: m => {
                            if (m.button === Qt.RightButton) {
                                bar.menuY = app.mapToItem(null, 0, app.height / 2).y
                                bar.menuKey = app.modelData
                            }
                            else if (m.button === Qt.MiddleButton) { if (app.it.entry) app.it.entry.execute() }
                            else Apps.activate(app.it)
                        }
                    }
                }
            }

            // Desktop name, written along the bar.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    anchors.centerIn: parent
                    rotation: -90
                    visible: implicitWidth < parent.height - 8
                    text: bar.activeId ? Ui.deskName(bar.activeId) : ""
                    font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.5
                    color: bar.activeId ? Ui.deskColor(bar.activeId) : Theme.accent
                    Behavior on color { ColorAnimation { duration: 220 } }
                }
            }

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Repeater {
                    model: SystemTray.items
                    delegate: Image {
                        required property var modelData
                        width: 18; height: 18
                        source: modelData.icon
                        sourceSize: Qt.size(36, 36)
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate()
                                else modelData.secondaryActivate()
                            }
                        }
                    }
                }
            }

            Sep {}

            // Status; a click on it or the gear opens the Bridge (control center) from the island.
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.g(0xF303)   // Arch Linux logo
                    font.family: Theme.iconFont; font.pixelSize: 17
                    color: Ui.sheet === "bridge" ? Theme.accent : Theme.text
                    rotation: Ui.sheet === "bridge" ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                CcPop {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.g(bar.muted ? 0xF075F : 0xF057E); color: Theme.purple
                    watch: bar.muted ? -1 : Math.round((bar.audio ? bar.audio.volume : 0) * 100)
                }
                CcPop {
                    Layout.alignment: Qt.AlignHCenter
                    readonly property bool on: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                    text: Theme.g(on ? 0xF00AF : 0xF00B2); color: on ? Theme.blue : Theme.subtext
                    watch: on
                }
                CcPop {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Ui.lan !== ""
                    text: Theme.g(Ui.lan === "up" ? 0xF0318 : 0xF0319)
                    color: Ui.lan === "up" ? Theme.text : Theme.subtext
                    watch: Ui.lan
                    ping: Ui.lan === "up"
                }
                CcPop {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.g(Ui.ssid !== "" ? 0xF0928 : 0xF092D)
                    color: Ui.ssid !== "" ? Theme.text : Theme.subtext
                    watch: Ui.ssid
                    ping: Ui.ssid !== ""
                }
                CcPop {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Ui.battery >= 0
                    text: Theme.g(Ui.charging ? 0xF0084 : 0xF0079)
                    color: Ui.battery < 20 && !Ui.charging ? Theme.red : Theme.accent
                    watch: Ui.charging
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Ui.battery >= 0
                    text: Ui.battery
                    font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold
                    color: Theme.subtext
                }
                TapHandler { onTapped: Ui.openSheet("bridge") }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 32; height: 32; radius: 16
                color: power.containsMouse ? Qt.rgba(1, 0.18, 0.39, 0.22) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: Theme.g(0xF0425)
                    font.family: Theme.iconFont; font.pixelSize: 17
                    color: Theme.red
                }
                MouseArea { id: power; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.openSheet("launch") }
            }
        }
    }
}
