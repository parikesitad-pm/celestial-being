pragma Singleton
import QtQuick

// Values mirror ~/.config/hypr/hyprlock.conf and hyprland.lua.
QtObject {
    readonly property color green: "#2ee6a8"
    readonly property color orange: "#ff9f1c"
    readonly property color blue: "#3b82f6"
    readonly property color purple: "#a855f7"
    readonly property color red: "#ff4d6d"
    readonly property color ink: "#e8f1ff"
    readonly property color night: "#070b14"
    readonly property color fieldFill: "#b0070b14"
    readonly property color scrim: "#a0070b14"

    readonly property string sans: "Inter"
    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var mac: [0.22, 1, 0.36, 1, 1, 1]
    readonly property var macSoft: [0.32, 0.72, 0, 1, 1, 1]

    // Hyprland "speed" is in tenths of a second: fadeIn 5, fadeOut 4, inputFieldDots 2, borderangle 40.
    readonly property int fadeIn: 500
    readonly property int fadeOut: 400
    readonly property int dots: 200
    readonly property int colorShift: 300
    readonly property real borderLoop: 4

    // Ignition and login sequence on the SDDM screen; hyprlock has no equivalent.
    readonly property int panelOpen: 700
    readonly property int ignite: 800
    readonly property int flareDecay: 650
    readonly property int settle: 1800
    readonly property int digitRoll: 450
    // How long the login waits so the charge-up is seen: the greeter dies as soon as login succeeds.
    readonly property int charge: 280
}
