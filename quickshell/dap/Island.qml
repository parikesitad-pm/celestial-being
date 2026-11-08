import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// The center of the bar: a pill (clock + system stats) that springs open into a panel with
// tabs when clicked, and widens for a few seconds when a notification arrives.
PanelWindow {
    id: win
    anchors { top: true }
    implicitWidth: 940
    implicitHeight: 900
    color: "transparent"
    // The bar moved to the left edge; the island now keeps the top strip clear of windows.
    exclusiveZone: 40
    WlrLayershell.namespace: "dap-island"
    WlrLayershell.keyboardFocus: Ui.island ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // Only the island takes input; the rest of this window lets clicks through to what's below.
    mask: Region { item: shape }

    HyprlandFocusGrab { windows: [win]; active: Ui.island; onCleared: Ui.cleared("island") }

    readonly property string mode: Ui.island ? "open" : (Ui.toast ? "toast" : "pill")
    readonly property bool narrow: !!screen && screen.width < 1300
    readonly property var tabs: ["Music", "Calendar", "Focus", "Todo", "Notif", "Control", "System", "Hangar"]
    readonly property int tab: Ui.islandTab
    property int lastTab: 0
    // Every tab enters the same way: a short slide from the side it came from, plus a fade.
    onTabChanged: {
        header.play("CELESTIAL BEING // " + tabs[tab].toUpperCase(), false)
        pageShift.x = tab > lastTab ? 18 : -18
        pages.opacity = 0
        lastTab = tab
        pageIn.restart()
    }
    ParallelAnimation {
        id: pageIn
        NumberAnimation { target: pageShift; property: "x"; to: 0; duration: 260; easing.type: Easing.OutExpo }
        NumberAnimation { target: pages; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
    onModeChanged: {
        if (mode !== "open") { Ui.power = false; return }
        if (Ui.power) { header.play("CELESTIAL BEING // SESSION", true); return }
        if (tab === 0 && !Ui.player) Ui.islandTab = 1
        header.play("CELESTIAL BEING // PILOT dap_", true)
    }

    // Under-damped on purpose: the island overshoots a little and settles, like a drop of liquid.
    component Spring: SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.25 }
    // Content fades in once the shape has mostly opened, and leaves fast.
    component Reveal: NumberAnimation { duration: 220; easing.type: Easing.OutCubic }

    // The Control tab grows to fit the control center, up to the screen height.
    readonly property real chrome: 32 + header.implicitHeight + 46
    readonly property real openHeight: Ui.power ? 32 + header.implicitHeight + 10 + powerSheet.implicitHeight + 4
        : tab === Ui.controlTab
        ? Math.min(chrome + control.implicitHeight + 4, (screen ? screen.height : 1080) - 60)
        : tab === 7 ? 470 : 388

    // Body hanging from the top edge, with concave fillets into it. Drawn under the content.
    IslandShape {
        id: ringGlow
        x: shape.x; y: 0
        w: shape.width; h: shape.height
        radius: shape.radius
        fillet: win.mode === "open" ? 18 : 12
        fill: win.mode === "pill" && pillArea.containsMouse ? Theme.glassStrong : Theme.glass
        // Measured: spinning on the always-visible pill cost ~18% of a core, so it only
        // travels while the island is open or showing a toast.
        spinning: win.mode !== "pill" && !Ui.dnd
        solid: Ui.dnd ? Qt.rgba(Theme.psycho.r, Theme.psycho.g, Theme.psycho.b, 0.45 + 0.55 * breathe) : "transparent"
        // NT-D breathes only while the island is open or toasting; the always-on pill stays still.
        property real breathe: 1
        SequentialAnimation on breathe {
            running: Ui.dnd && win.mode !== "pill"
            loops: Animation.Infinite
            onRunningChanged: if (!running) ringGlow.breathe = 1
            NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
        }
        // Closed: GN green radar. Open or toasting: anime blue / Trans-Am red.
        colors: win.mode === "pill" ? [Theme.gn, Qt.darker(Theme.gn, 2.6), Theme.gn, Qt.darker(Theme.gn, 2.6)] : null
        Behavior on fillet { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    }

    Rectangle {
        id: shape
        anchors.horizontalCenter: parent.horizontalCenter
        // Hangar (apps only) opens extra wide.
        width: win.mode === "open" ? (win.tab === 7 && !Ui.power ? 900 : 600) : win.mode === "toast" ? 460 : pill.implicitWidth + 40
        height: win.mode === "open" ? win.openHeight : win.mode === "toast" ? 64 : 36
        radius: win.mode === "open" ? 28 : win.mode === "toast" ? 24 : 18
        Behavior on width { Spring {} }
        Behavior on height { Spring {} }
        Behavior on radius { Spring {} }
        // The visible body is IslandShape (attached to the top edge); this item sizes, clips and masks.
        color: "transparent"
        clip: true

        MouseArea {
            id: pillArea
            anchors.fill: parent
            enabled: win.mode !== "open"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (win.mode === "toast") Ui.islandTab = 4
                Ui.toggle("island")
            }
        }

        IslandPill {
            id: pill
            anchors.centerIn: parent
            narrow: win.narrow
            // Hidden at once when the island grows, so it never overlaps the panel mid-spring;
            // on close it waits for the shape to shrink before fading back in.
            visible: win.mode === "pill"
            opacity: visible ? 1 : 0
            Behavior on opacity {
                SequentialAnimation { PauseAnimation { duration: 180 } NumberAnimation { duration: 220 } }
            }
        }

        IslandToast {
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 18
            notif: Ui.toast
            visible: win.mode === "toast"
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 260 } }
        }

        // Caution tape along the top edge only for critical toasts, so it still reads as an alarm.
        HazardStripe {
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            height: 5
            visible: win.mode === "toast" && !!Ui.toast && Ui.toast.critical
            running: visible
        }

        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 16
            enabled: win.mode === "open"
            focus: win.mode === "open"
            opacity: win.mode === "open" ? 1 : 0
            transform: Translate { y: win.mode === "open" ? 0 : -10; Behavior on y { Reveal {} } }
            Behavior on opacity { NumberAnimation { duration: win.mode === "open" ? 260 : 90; easing.type: Easing.OutCubic } }
            Keys.onEscapePressed: Ui.island = false

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                IslandHeader {
                    id: header
                    Layout.fillWidth: true
                    running: win.mode === "open"
                }

                RowLayout {
                    visible: !Ui.power
                    Layout.fillWidth: true
                    spacing: 8
                    Item {
                        implicitWidth: tabRow.implicitWidth
                        implicitHeight: 26
                        // One highlight shared by every tab: it springs to the tab you pick.
                        Rectangle {
                            readonly property Item target: tabRepeater.count > win.tab ? tabRepeater.itemAt(win.tab) : null
                            x: target ? target.x : 0
                            width: target ? target.width : 0
                            height: 26; radius: 13
                            color: Theme.tileHover
                            Behavior on x { Spring {} }
                            Behavior on width { Spring {} }
                        }
                        Row {
                            id: tabRow
                            spacing: 4
                            Repeater {
                                id: tabRepeater
                                model: win.tabs
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    readonly property bool current: win.tab === index
                                    width: tabText.implicitWidth + 22; height: 26; radius: 13
                                    color: !current && tabArea.containsMouse ? Theme.tile : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text {
                                        id: tabText
                                        anchors.centerIn: parent
                                        text: modelData + (index === 4 && Ui.notifs.length > 0 ? " " + Ui.notifs.length : "")
                                        font.family: Theme.font; font.pixelSize: 12
                                        font.weight: current ? Font.Bold : Font.Normal
                                        color: current ? Theme.text : Theme.subtext
                                    }
                                    MouseArea {
                                        id: tabArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Ui.islandTab = index
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                PowerSheet {
                    id: powerSheet
                    Layout.fillWidth: true
                    visible: Ui.power
                }

                StackLayout {
                    visible: !Ui.power
                    id: pages
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: win.tab
                    transform: Translate { id: pageShift }
                    NotchMusic { active: win.mode === "open" && win.tab === 0 }
                    NotchCalendar { shown: win.mode === "open" && win.tab === 1 }
                    NotchFocus {}
                    NotchTodo {}
                    NotchNotifs {}
                    Flickable {
                        contentHeight: control.implicitHeight
                        clip: true
                        interactive: contentHeight > height
                        ControlPanel {
                            id: control
                            width: parent.width
                            shown: win.mode === "open" && win.tab === Ui.controlTab
                            onShownChanged: if (shown) forceActiveFocus()
                        }
                    }
                    NotchSystem {}
                    NotchHangar { shown: win.mode === "open" && win.tab === 7 && !Ui.power }
                }
            }
        }

        // Drawn last so it sits on top of the content edge, like a window's active border.
    }
}
