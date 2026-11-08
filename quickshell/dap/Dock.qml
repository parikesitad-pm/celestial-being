import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// macOS-style dock: auto-hide, magnification, running dots, bounce until the launched app opens.
// Native to Hyprland (no nwg-dock).
PanelWindow {
    id: win
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 210
    // Hidden, the surface is unmapped, so the compositor has nothing to draw or blur here.
    visible: revealed || off < hiddenOff
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "dap-dock"
    WlrLayershell.keyboardFocus: menuKey !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: hit }

    readonly property int hiddenOff: 84
    readonly property bool wantOpen: edgeHover.hovered || hov.hovered || menuKey !== ""
    property bool revealed: false
    property real off: revealed ? 0 : hiddenOff
    Behavior on off {
        NumberAnimation {
            duration: win.revealed ? 240 : 170
            easing.type: win.revealed ? Easing.OutExpo : Easing.InQuad
        }
    }
    onWantOpenChanged: {
        if (wantOpen) { hideDelay.stop(); if (!revealed) showDelay.restart() }
        else { showDelay.stop(); hideDelay.restart() }
    }
    // Trigger strip along the whole bottom edge, in its own surface: it stays mapped when the
    // dock is not, and keeps the dock open while the pointer sits on the edge away from it.
    property PanelWindow edgeStrip: PanelWindow {
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 2
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "dap-dock-edge"
        HoverHandler { id: edgeHover }
    }
    Timer { id: showDelay; interval: 100; onTriggered: win.revealed = true }
    Timer { id: hideDelay; interval: 400; onTriggered: win.revealed = false }

    property string menuKey: ""      // item whose right-click menu is open
    property real menuCenter: 0      // that icon's resting center, on the resting layout
    readonly property var menuItem: byKey[menuKey] || null
    function openMenu(key, center) { menuCenter = center; menuKey = key; menu.forceActiveFocus() }
    HyprlandFocusGrab { windows: [win]; active: win.menuKey !== ""; onCleared: win.menuKey = "" }

    readonly property int base: 46
    readonly property int peak: 74
    readonly property int gap: 8
    readonly property int pad: 12
    property real mx: -1000          // pointer x on the resting layout, -1000 = not hovering

    // lastIpcObject stays empty on a new window until refreshToplevels() runs; appId is set right away.
    function clsOf(t) { return (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject.class) || "" }
    function matches(entry, cls) {
        if (!entry || !cls) return false
        const c = cls.toLowerCase()
        return entry.id.toLowerCase() === c || (entry.startupClass || "").toLowerCase() === c || entry.id.toLowerCase().endsWith("." + c) || entry.id.toLowerCase().includes(c)
    }
    // DesktopEntries scans asynchronously and byId() is not reactive, so without this
    // the pinned apps stay missing after login until a window opens or closes.
    property int entriesRevision: 0
    Timer { id: entriesSettled; interval: 50; onTriggered: win.entriesRevision++ }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { entriesSettled.restart() }
    }

    readonly property var items: {
        void entriesRevision
        const tls = Hyprland.toplevels.values
        const out = [{ key: "launcher", entry: null, wins: [], cls: "appgrid", pinned: true, isLauncher: true }], used = {}
        for (const id of Ui.pinned) {
            const e = DesktopEntries.byId(id)
            if (!e) continue
            const w = tls.filter(t => matches(e, clsOf(t)))
            w.forEach(t => used[t.address] = true)
            out.push({ key: id, entry: e, wins: w, cls: e.id, pinned: true })
        }
        const extra = {}
        for (const t of tls) {
            const c = clsOf(t)
            if (used[t.address] || c === "") continue
            if (!extra[c]) { extra[c] = { key: "c:" + c, entry: DesktopEntries.heuristicLookup(c), wins: [], cls: c, pinned: false }; out.push(extra[c]) }
            extra[c].wins.push(t)
        }
        return out
    }
    readonly property var byKey: {
        const m = {}
        for (const it of items) m[it.key] = it
        return m
    }
    readonly property int pinnedCount: items.filter(it => it.pinned).length
    // Keys are plain strings, so delegates survive window changes and keep their animation state.
    ScriptModel { id: keys; values: win.items.map(it => it.key) }

    // Magnification is measured against the resting layout, not the live icon positions.
    // Live positions shift as icons grow, which feeds back into the size and makes it jitter.
    readonly property real restWidth: items.length * base + Math.max(0, items.length - 1) * gap + pad * 2
    readonly property real restLeft: (width - restWidth) / 2

    function activate(it) {
        if (it.wins.length > 0) {
            const t = it.wins[0]
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })")
        } else if (it.entry) it.entry.execute()
    }

    Item {
        id: hit
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        width: Math.max(pill.width + 40, menu.width + 16)
        height: win.menuKey !== "" ? 206 : (hov.hovered ? 130 : 76)
        // Passive handler: it keeps tracking while the icon MouseAreas hold the hover.
        HoverHandler {
            id: hov
            onHoveredChanged: if (!hovered) win.mx = -1000
            onPointChanged: if (hovered) win.mx = hit.x + point.position.x - win.restLeft
        }

        Rectangle {
            id: pill
            transform: Translate { y: win.off }
            anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
            height: win.base + 18
            width: row.width + win.pad * 2
            radius: 24
            color: Theme.glass; border.width: 1; border.color: Theme.stroke

            Row {
                id: row
                anchors { bottom: parent.bottom; bottomMargin: 9; horizontalCenter: parent.horizontalCenter }
                spacing: win.gap
                Repeater {
                    model: keys
                    delegate: Item {
                        id: ic
                        required property string modelData
                        required property int index
                        readonly property var it: win.byKey[modelData] || ({ entry: null, wins: [], cls: "", pinned: true })
                        readonly property int winCount: it.wins.length
                        readonly property real restCenter: win.pad + index * (win.base + win.gap) + win.base / 2
                        readonly property real d: Math.abs(win.mx - restCenter)
                        readonly property real target: win.mx < -500 ? win.base : win.base + (win.peak - win.base) * Math.exp(-(d * d) / (2 * 55 * 55))
                        property real sz: win.base
                        property real appear: 0
                        property real bounce: 0
                        property bool launching: false

                        onTargetChanged: sz = target
                        Behavior on sz { SpringAnimation { spring: 14; damping: 1; epsilon: 0.05 } }
                        NumberAnimation on appear { from: 0; to: 1; duration: 240; easing.type: Easing.OutExpo }

                        anchors.bottom: parent ? parent.bottom : undefined
                        width: sz * appear; height: sz

                        onWinCountChanged: if (winCount > 0) launching = false
                        function launch() {
                            if (!it.entry) return
                            launching = true
                            launchTimeout.restart()
                            it.entry.execute()
                        }
                        Timer { id: launchTimeout; interval: 10000; onTriggered: ic.launching = false }
                        SequentialAnimation {
                            running: ic.launching
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { target: ic; property: "bounce"; to: 22; duration: 240; easing.type: Easing.OutQuad }
                            NumberAnimation { target: ic; property: "bounce"; to: 0; duration: 240; easing.type: Easing.InQuad }
                        }

                        // Separates pinned apps from the other running ones.
                        Rectangle {
                            visible: ic.index === win.pinnedCount && win.pinnedCount > 0
                            x: -win.gap / 2 - 0.5
                            anchors.bottom: parent.bottom
                            width: 1; height: win.base; color: Theme.stroke
                        }
                        // Apps button: drawn here because no theme icon reads as an app grid.
                        Rectangle {
                            visible: !!ic.it.isLauncher
                            anchors.centerIn: parent
                            width: win.base; height: win.base; radius: 12
                            scale: ic.sz / win.base
                            opacity: (ma.pressed ? 0.65 : 1) * ic.appear
                            color: Theme.tile; border.width: 1; border.color: Theme.stroke
                            Grid {
                                anchors.centerIn: parent
                                columns: 3; spacing: 5
                                Repeater { model: 9; Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent } }
                            }
                        }
                        Image {
                            visible: !ic.it.isLauncher
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -ic.bounce
                            width: ic.sz; height: ic.sz
                            sourceSize: Qt.size(128, 128)
                            smooth: true; mipmap: true
                            opacity: (ma.pressed ? 0.65 : 1) * ic.appear
                            source: Quickshell.iconPath(ic.it.entry ? ic.it.entry.icon : ic.it.cls.toLowerCase(), "application-x-executable")
                        }
                        Rectangle {
                            visible: ic.winCount > 0
                            width: 4; height: 4; radius: 2; color: Theme.text; opacity: 0.85
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 2 }
                        }
                        // name tooltip
                        Rectangle {
                            visible: ma.containsMouse && win.menuKey === ""
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 8 }
                            width: tip.implicitWidth + 20; height: 26; radius: 13
                            color: Theme.glassStrong; border.width: 1; border.color: Theme.stroke
                            Text { id: tip; anchors.centerIn: parent; text: ic.it.isLauncher ? "Apps" : ic.it.entry ? ic.it.entry.name : ic.it.cls
                                   font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.text }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: m => {
                                if (ic.it.isLauncher) {
                                    if (m.button === Qt.LeftButton) Ui.toggle("launcher")
                                } else if (m.button === Qt.RightButton) {
                                    win.openMenu(ic.modelData, ic.restCenter)
                                } else if (m.button === Qt.MiddleButton || ic.winCount === 0) {
                                    ic.launch()
                                } else win.activate(ic.it)
                            }
                        }
                    }
                }
            }
        }

        DockMenu {
            id: menu
            dock: win
            readonly property real wanted: win.restLeft + win.menuCenter - hit.x - width / 2
            x: Math.max(0, Math.min(wanted, hit.width - width))
            anchors { bottom: parent.bottom; bottomMargin: 94 }
        }
    }
}
