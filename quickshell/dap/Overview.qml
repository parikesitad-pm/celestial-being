import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Mission Control: workspace thumbnails on top, the viewed workspace's windows below.
// Drag a window onto a workspace thumbnail (or "+") to move it there. Click a thumbnail to go.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    // Opens only on the monitor focused at open time, and stays there while the pointer roams.
    property bool shown: false
    // one master progress drives everything: 0 = desktop, 1 = Mission Control
    property real prog: shown ? 1 : 0
    Behavior on prog { NumberAnimation {
        duration: win.shown ? 480 : 320
        easing.type: Easing.BezierSpline
        easing.bezierCurve: win.shown ? [0.16, 1, 0.3, 1, 1, 1] : [0.4, 0, 0.2, 1, 1, 1]
    } }
    visible: shown || prog > 0.001
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var mon: Hyprland.monitorFor(screen)
    readonly property int activeId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : 1
    property int viewId: 1
    // true while a window tile is being dragged: freezes viewId so the dragged tile isn't rebuilt mid-drag
    property bool dragging: false
    // the workspace card a drop would land on; the pointer alone decides it
    property var dropCard: null

    // Every workspace on every monitor, laptop-to-external order, so a window can be sent across screens.
    readonly property var wsIds: {
        const list = Hyprland.workspaces.values.filter(w => w.id > 0)
        const out = list.sort((a, b) => monX(a) - monX(b) || a.id - b.id).map(w => w.id)
        if (out.indexOf(activeId) < 0) out.push(activeId)
        return out
    }
    readonly property int newId: { let i = 1; while (wsIds.indexOf(i) >= 0) i++; return i }
    readonly property bool multiMonitor: Quickshell.screens.length > 1

    function monX(w) { return w && w.monitor ? w.monitor.x : 0 }
    function monY(w) { return w && w.monitor ? w.monitor.y : 0 }
    function monitorLabel(id) {
        const w = Hyprland.workspaces.values.find(w => w.id === id)
        if (!w || !w.monitor) return ""
        return w.monitor.name.startsWith("eDP") ? "Laptop" : "External"
    }
    // Forgiving target: anywhere above the window area snaps to the nearest card, gaps and labels included.
    function cardUnder(from, x, y) {
        const p = from.mapToItem(stripRow, x, y)
        if (p.y > strip.height + 28 || p.x < -40 || p.x > stripRow.width + 40) return null
        let best = null, bestDist = Infinity
        for (const c of stripRow.children) {
            if (c.wsId === undefined) continue
            const d = Math.abs(p.x - (c.x + c.width / 2))
            if (d < bestDist) { best = c; bestDist = d }
        }
        return best
    }

    function winsOf(id) {
        return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === id && t.wayland)
    }
    function go(id) { Ui.overview = false; Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })") }
    function addDesk() { Ui.overview = false; Ui.addDesk(newId, true) }
    function moveTo(t, id) {
        if (id === newId) Ui.addDesk(id, false)   // dropping on "New desktop" creates it for real
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + id + ", window = \"address:0x" + t.address + "\", follow = false })")
        refresh.restart()
    }
    function focusWin(t) {
        Ui.overview = false
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })")
    }
    Timer { id: refresh; interval: 120; onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces() } }

    Connections {
        target: Ui
        function onOverviewChanged() {
            const focused = Hyprland.focusedMonitor
            win.shown = Ui.overview && !!focused && focused.name === win.screen.name
            if (win.shown) { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces(); win.viewId = win.activeId; root.forceActiveFocus() }
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0.02, 0.03, 0.07, 0.62) : Qt.rgba(0.9, 0.93, 1, 0.55)
        opacity: win.prog
        MouseArea { anchors.fill: parent; onClicked: Ui.overview = false }
    }

    FocusScope {
        id: root
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.overview = false
        Keys.onLeftPressed: { if (win.dragging) return; const i = win.wsIds.indexOf(win.viewId); if (i > 0) win.viewId = win.wsIds[i - 1] }
        Keys.onRightPressed: { const i = win.wsIds.indexOf(win.viewId); if (i < win.wsIds.length - 1) win.viewId = win.wsIds[i + 1] }
        Keys.onReturnPressed: win.go(win.viewId)

        // ───── workspace strip ─────
        Item {
            id: strip
            z: 1
            anchors { top: parent.top; topMargin: 64; horizontalCenter: parent.horizontalCenter }
            width: stripRow.implicitWidth
            height: cardH + 34
            // Shrinks as desktops are added, so the whole strip stays on screen.
            readonly property real cardW: {
                const n = win.wsIds.length + 1
                return Math.min(230, (win.width - 80 - stripRow.spacing * (n - 1)) / n)
            }
            readonly property real cardH: cardW * win.height / win.width
            opacity: Math.min(1, win.prog * 1.6)
            transform: Translate { y: -(strip.height + 80) * (1 - win.prog) }

            Row {
                id: stripRow
                spacing: 16
                Repeater {
                    model: win.wsIds.concat([-1])
                    delegate: Item {
                        id: card
                        required property int modelData
                        readonly property bool isNew: modelData === -1
                        readonly property int wsId: isNew ? win.newId : modelData
                        readonly property bool current: !isNew && wsId === win.viewId
                        readonly property bool hot: win.dropCard === card
                        width: strip.cardW; height: strip.cardH + 34
                        scale: hot ? 1.07 : 1
                        Behavior on scale { SpringAnimation { spring: 8; damping: 0.4; epsilon: 0.001 } }

                        Rectangle {
                            id: thumb
                            width: parent.width; height: strip.cardH
                            radius: 12
                            color: Qt.rgba(0.05, 0.08, 0.15, 1)
                            border.width: card.current || card.hot ? 2 : 1
                            border.color: card.current || card.hot ? (card.isNew ? Theme.accent : Ui.deskColor(card.wsId)) : Theme.stroke
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/Pictures/wallpapers/gundam-dark.jpg"
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(480, 270)
                                opacity: card.isNew ? 0.35 : 1
                            }
                            Rectangle { anchors.fill: parent; color: "#000000"; opacity: card.current ? 0 : 0.18 }
                            Text { visible: card.isNew; anchors.centerIn: parent; text: "+"; font.pixelSize: 38; font.family: Theme.font; color: Theme.subtext }
                            Item {
                                visible: !card.isNew
                                anchors.fill: parent
                                readonly property real k: width / win.width
                                Repeater {
                                    model: card.isNew ? [] : win.winsOf(card.wsId)
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property var o: modelData.lastIpcObject
                                        x: (o.at ? o.at[0] - win.monX(modelData.workspace) : 0) * parent.k
                                        y: (o.at ? o.at[1] - win.monY(modelData.workspace) : 0) * parent.k
                                        width: (o.size ? o.size[0] : 100) * parent.k
                                        height: (o.size ? o.size[1] : 100) * parent.k
                                        radius: 4; color: Qt.rgba(0.08, 0.1, 0.16, 0.92); clip: true
                                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.18)
                                        Image {
                                            anchors.centerIn: parent
                                            width: Math.min(parent.width, parent.height) * 0.5; height: width
                                            sourceSize: Qt.size(64, 64)
                                            source: Quickshell.iconPath((DesktopEntries.heuristicLookup(o.class || "") || { icon: (o.class || "").toLowerCase() }).icon, "application-x-executable")
                                        }
                                        ScreencopyView { anchors.fill: parent; captureSource: win.visible ? modelData.wayland : null; live: true }
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: if (!card.isNew && !win.dragging) win.viewId = card.wsId
                                onClicked: card.isNew ? win.addDesk() : win.go(card.wsId)
                            }
                            // Added desktops can be closed once they're empty, like Mission Control.
                            Rectangle {
                                readonly property bool removable: !card.isNew && card.wsId > Ui.baseDesks
                                    && card.wsId !== win.activeId && win.winsOf(card.wsId).length === 0
                                anchors { top: parent.top; right: parent.right; margins: 6 }
                                width: 22; height: 22; radius: 11
                                visible: removable && (card.current || closeArea.containsMouse)
                                color: closeArea.containsMouse ? Theme.red : Theme.glassStrong
                                border.width: 1; border.color: Theme.stroke
                                Text { anchors.centerIn: parent; text: Theme.g(0xF0156); font.family: Theme.iconFont; font.pixelSize: 13; color: Theme.text }
                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent; anchors.margins: -4
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { Ui.removeDesk(card.wsId); refresh.restart() }
                                }
                            }
                        }
                        Text {
                            anchors { top: thumb.bottom; topMargin: 8; left: parent.left; right: parent.right }
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: card.isNew ? "New desktop" : Ui.deskName(card.wsId) + (win.multiMonitor ? " · " + win.monitorLabel(card.wsId) : "")
                            font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                            color: card.current || card.hot ? (card.isNew ? Theme.accent : Ui.deskColor(card.wsId)) : Theme.subtext
                        }
                    }
                }
            }
        }

        // ───── windows of the viewed workspace ─────
        Item {
            id: area
            z: 2
            anchors { top: strip.bottom; topMargin: 28; bottom: parent.bottom; bottomMargin: 56; left: parent.left; right: parent.right; leftMargin: 80; rightMargin: 80 }
            readonly property var items: win.winsOf(win.viewId)
            readonly property int n: items.length
            readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(n * width / Math.max(1, height))))
            readonly property int rows: Math.max(1, Math.ceil(n / cols))
            readonly property real cw: width / cols
            readonly property real ch: height / rows

            Text {
                visible: area.n === 0; anchors.centerIn: parent
                text: "No windows on " + Ui.deskName(win.viewId)
                font.family: Theme.font; font.pixelSize: 15; color: Theme.subtext
            }

            Repeater {
                model: area.items
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property var o: modelData.lastIpcObject
                    readonly property real ar: (o.size ? o.size[0] / Math.max(1, o.size[1]) : 16 / 9)
                    readonly property real availW: area.cw - 24
                    readonly property real availH: area.ch - 52
                    readonly property real tw: Math.min(availW, availH * ar)
                    readonly property real th: tw / ar
                    x: (index % area.cols) * area.cw
                    y: Math.floor(index / area.cols) * area.ch
                    width: area.cw; height: area.ch
                    readonly property bool fromReal: !!(modelData.workspace && modelData.workspace.id === win.activeId && o && o.at && o.size)
                    // where the window really is on screen, relative to this cell
                    readonly property real rx: fromReal ? o.at[0] - win.monX(modelData.workspace) - area.x - x : (width - tw) / 2
                    readonly property real ry: fromReal ? o.at[1] - win.monY(modelData.workspace) - area.y - y : (height - 36 - th) / 2
                    readonly property real rw: fromReal ? o.size[0] : tw * 0.9
                    readonly property real rh: fromReal ? o.size[1] : th * 0.9
                    readonly property real hx: (width - tw) / 2
                    readonly property real hy: (height - 36 - th) / 2
                    property real appear: fromReal ? 1 : 0
                    Component.onCompleted: appear = 1
                    Behavior on appear { NumberAnimation { duration: 220 } }
                    opacity: appear

                    Item {
                        id: tile
                        property var tl: cell.modelData
                        property real dx: 0
                        property real dy: 0
                        property bool dragging: false
                        // pointer's offset from the tile center at grab; pull glides the tile's center onto the pointer
                        property real grabX: 0
                        property real grabY: 0
                        property real pull: 0
                        Behavior on pull { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        onDraggingChanged: win.dragging = dragging
                        Component.onDestruction: if (dragging) { win.dragging = false; win.dropCard = null }
                        readonly property real k: win.prog
                        x: cell.rx + (cell.hx - cell.rx) * k + dx + grabX * pull
                        y: cell.ry + (cell.hy - cell.ry) * k + dy + grabY * pull
                        width: cell.rw + (cell.tw - cell.rw) * k
                        height: cell.rh + (cell.th - cell.rh) * k
                        Behavior on dx { enabled: !tile.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                        Behavior on dy { enabled: !tile.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                        // 120px wide while dragged: narrower than a 230px card, so the target stays visible around it
                        scale: tile.dragging ? Math.min(1, 120 / Math.max(1, width)) : (dm.containsMouse && win.prog > 0.95 ? 1.03 : 1)
                        Behavior on scale { SpringAnimation { spring: 8; damping: 0.4; epsilon: 0.001 } }
                        z: tile.dragging ? 100 : 0

                        // soft drop shadow, like macOS
                        Rectangle { anchors.fill: parent; anchors.margins: -6; anchors.topMargin: -2; anchors.bottomMargin: -12; radius: 16
                            color: "#000000"; opacity: 0.28 * win.prog; z: -1 }
                        Rectangle { anchors.fill: parent; anchors.margins: -2; radius: 12 * win.prog; color: "transparent"; z: 1
                            border.width: dm.containsMouse ? 2 : 1; border.color: dm.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.14 * win.prog) }
                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: win.visible ? cell.modelData.wayland : null
                            live: true
                        }
                        MouseArea {
                            id: dm
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            property point start
                            property bool moved: false
                            onPressed: m => {
                                start = mapToItem(area, m.x, m.y)
                                moved = false
                                const c = tile.mapToItem(area, tile.width / 2, tile.height / 2)
                                tile.grabX = start.x - c.x
                                tile.grabY = start.y - c.y
                            }
                            onPositionChanged: m => {
                                if (!pressed) return
                                const p = mapToItem(area, m.x, m.y)
                                if (!moved && Math.hypot(p.x - start.x, p.y - start.y) > 8) { moved = true; tile.dragging = true; tile.pull = 1 }
                                if (moved) {
                                    tile.dx = p.x - start.x; tile.dy = p.y - start.y
                                    win.dropCard = win.cardUnder(dm, m.x, m.y)
                                }
                            }
                            onReleased: m => {
                                if (!moved) return
                                const c = win.cardUnder(dm, m.x, m.y)
                                if (c) win.moveTo(tile.tl, c.wsId)
                                win.dropCard = null
                                tile.dragging = false
                                tile.pull = 0
                                tile.dx = 0; tile.dy = 0
                            }
                            onClicked: if (!moved) win.focusWin(cell.modelData)
                        }
                    }
                    Text {
                        anchors { top: tile.bottom; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                        width: cell.tw; horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.title || cell.o.class || ""
                        font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: Theme.text; elide: Text.ElideRight
                        opacity: tile.dragging ? 0 : Math.max(0, win.prog * 2 - 1)
                    }
                }
            }
        }
    }
}
