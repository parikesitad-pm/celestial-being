pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: t
    property bool dark: true

    readonly property color glass:       dark ? Qt.rgba(0.03, 0.05, 0.10, 0.55) : Qt.rgba(0.97, 0.98, 1.00, 0.55)
    readonly property color glassStrong: dark ? Qt.rgba(0.03, 0.05, 0.10, 0.72) : Qt.rgba(0.97, 0.98, 1.00, 0.74)
    readonly property color stroke:      dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color text:        dark ? "#f2f6ff" : "#101624"
    readonly property color subtext:     dark ? "#a7b3cc" : "#3a4358"
    readonly property color tile:        dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color tileHover:   dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color gn: "#2ee6a8"           // GN green
    readonly property color transAmRed: "#ff2e63"
    readonly property color anime: "#4fb6ff"        // Cruise / Standby window edges   // Trans-Am (performance profile)
    readonly property color monoEye: "#ff4d9d"      // Zaku mono-eye (loading)
    readonly property color psycho: "#ff1f3d"       // Unicorn psycho-frame (NT-D = Do Not Disturb)
    // 0 = GN green, 1 = Trans-Am red; eased so the whole shell flushes red instead of snapping.
    property real transAmT: Ui.transAm ? 1 : 0
    Behavior on transAmT { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    readonly property color accent: Qt.rgba(gn.r + (transAmRed.r - gn.r) * transAmT,
                                            gn.g + (transAmRed.g - gn.g) * transAmT,
                                            gn.b + (transAmRed.b - gn.b) * transAmT, 1)
    readonly property color gold:   "#f2b705"   // Celestial Being emblem
    readonly property color blue:   "#3b82f6"
    readonly property color purple: "#a855f7"
    readonly property color orange: "#ff9f1c"
    readonly property color red:    "#ff4d6d"
    readonly property color onTint: "#04120d"   // text on any filled accent tile
    // Anime blue, or red in Trans-Am. Same stops and speed
    // as what Ui.applyBorder sends to Hyprland.
    readonly property color desk: Ui.deskColor(Ui.activeDesk)
    readonly property var border: [desk, Qt.darker(desk, 2.2), desk, Qt.darker(desk, 2.2)]
    readonly property int borderLoopMs: 4000

    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property string assets:   Quickshell.env("HOME") + "/.local/share/dap-shell/"
    readonly property string scripts:  Quickshell.env("HOME") + "/.config/hypr/scripts/"

    function g(cp) { return String.fromCodePoint(cp) }
}
