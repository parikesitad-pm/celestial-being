import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Control center main page: toggles, sliders, power profiles, displays, now playing, session.
Flow {
    id: mainPage
    required property var cc
    spacing: 8
    // 12-column grid with 8 px gaps across whatever width the island gives it.
    readonly property real cell: (width - 88) / 12
    function span(n) { return Math.floor(n * cell + (n - 1) * 8) }

    Tile {
        width: mainPage.span(6)
        glyph: Theme.g(mainPage.cc.wifiOn ? 0xF0928 : 0xF092D); title: "Wi-Fi"
        sub: !mainPage.cc.wifiOn ? "Off" : (Ui.ssid !== "" ? Ui.ssid : "Not connected"); on: mainPage.cc.wifiOn
        chevron: true; onChevronClicked: mainPage.cc.openPage("wifi")
        onClicked: { mainPage.cc.wifiOn = !mainPage.cc.wifiOn; Ui.sh("nmcli radio wifi " + (mainPage.cc.wifiOn ? "on" : "off")) }
    }
    Tile {
        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property var linked: adapter ? adapter.devices.values.find(d => d.connected) : null
        width: mainPage.span(6)
        glyph: Theme.g(on ? 0xF00AF : 0xF00B2); title: "Bluetooth"; onColor: Theme.blue
        on: !!adapter && adapter.enabled
        sub: !adapter ? "Unavailable" : (!on ? "Off" : (linked ? linked.name : "On"))
        interactive: !!adapter
        chevron: !!adapter; onChevronClicked: mainPage.cc.openPage("bluetooth")
        onClicked: adapter.enabled = !adapter.enabled
    }
    Tile {
        width: mainPage.span(6)
        glyph: Theme.g(Theme.dark ? 0xF0594 : 0xF0599); title: Theme.dark ? "Dark" : "Light"; sub: "Appearance"
        onClicked: { Theme.dark = !Theme.dark; Ui.sh(Theme.scripts + "theme.sh " + (Theme.dark ? "dark" : "light")) }
    }
    Tile {
        width: mainPage.span(6)
        glyph: Theme.g(Ui.dnd ? 0xF009B : 0xF009C); title: "NT-D"; sub: Ui.dnd ? "Do Not Disturb" : "Off"; onColor: Theme.psycho; on: Ui.dnd
        onClicked: Ui.dnd = !Ui.dnd
    }

    Slide {
        readonly property var audio: mainPage.cc.sink ? mainPage.cc.sink.audio : null
        width: mainPage.span(12)
        muted: !!audio && audio.muted
        // mute / off / low / medium / high
        glyph: Theme.g(muted ? 0xF075F : value < 1 ? 0xF0581 : value < 34 ? 0xF057F : value < 67 ? 0xF0580 : 0xF057E)
        value: audio ? audio.volume * 100 : 0
        onMoved: v => { if (audio) { audio.muted = false; audio.volume = v / 100 } }
        onGlyphClicked: if (audio) audio.muted = !audio.muted
        picker: true; onPickerClicked: mainPage.cc.openPage("audio")
    }
    Slide {
        readonly property var audio: mainPage.cc.mic ? mainPage.cc.mic.audio : null
        width: mainPage.span(12)
        visible: !!mainPage.cc.mic
        muted: !!audio && audio.muted
        glyph: Theme.g(muted ? 0xF036D : 0xF036C)
        value: audio ? audio.volume * 100 : 0
        onMoved: v => { if (audio) { audio.muted = false; audio.volume = v / 100 } }
        onGlyphClicked: if (audio) audio.muted = !audio.muted
        picker: true; onPickerClicked: mainPage.cc.openPage("audio")
    }
    Slide {
        width: mainPage.span(12)
        // dim / half / full sun, turning a quarter as it goes from 0 to 100
        glyph: Theme.g(value < 34 ? 0xF00DE : value < 67 ? 0xF00DF : 0xF00E0)
        glyphTurn: value * 0.9
        value: mainPage.cc.brightness
        onMoved: v => { mainPage.cc.brightness = Math.max(1, v); mainPage.cc.setBrightnessLater() }
    }

    Repeater {
        model: [{ k: "power-saver", g: 0xF032A, t: "Standby" }, { k: "balanced", g: 0xF0E8A, t: "Cruise" }, { k: "performance", g: 0xF0E7B, t: "Trans-Am" }]
        delegate: Tile {
            required property var modelData
            width: mainPage.span(4); compact: true
            glyph: Theme.g(modelData.g); title: modelData.t; on: Ui.profile === modelData.k; onColor: modelData.k === "performance" ? Theme.transAmRed : Theme.orange
            onClicked: { Ui.profile = modelData.k; Ui.sh("powerprofilesctl set " + modelData.k) }
        }
    }

    // external display: PC screen only / duplicate / extend, plus portrait
    Repeater {
        model: mainPage.cc.dispMode === "none" ? [] : [{ k: "pc", g: 0xF109, t: "PC" }, { k: "mirror", g: 0xF24D, t: "Copy" }, { k: "extend", g: 0xF108, t: "Extend" }]
        delegate: Tile {
            required property var modelData
            width: mainPage.span(3); compact: true
            glyph: Theme.g(modelData.g); title: modelData.t; on: mainPage.cc.dispMode === modelData.k; onColor: Theme.blue
            onClicked: mainPage.cc.setDisplay(modelData.k)
        }
    }
    Tile {
        width: mainPage.span(3); compact: true
        visible: mainPage.cc.dispMode !== "none"
        glyph: Theme.g(0xF10B); title: "Portrait"; on: mainPage.cc.dispPortrait; onColor: Theme.blue
        onClicked: { mainPage.cc.dispPortrait = !mainPage.cc.dispPortrait; Ui.sh(Theme.scripts + "display.sh portrait") }
    }
    PickRow {
        width: mainPage.span(12)
        visible: mainPage.cc.dispMode === "extend"
        title: "Arrange displays"
        sub: "External on the " + mainPage.cc.dispSide
        onPicked: mainPage.cc.openPage("display")
    }

    // now playing
    Rectangle {
        width: mainPage.span(12)
        visible: mainPage.cc.player !== null
        implicitHeight: 60; radius: 18; color: Theme.tile
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 8; spacing: 2
            ColumnLayout {
                Layout.fillWidth: true; Layout.rightMargin: 6; spacing: 1
                Text { text: mainPage.cc.player ? (mainPage.cc.player.trackTitle || mainPage.cc.player.identity) : ""; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.text; elide: Text.ElideRight; Layout.fillWidth: true; renderType: Text.NativeRendering }
                Text { text: mainPage.cc.player ? mainPage.cc.player.trackArtist : ""; visible: text !== ""; font.family: Theme.font; font.pixelSize: 11; color: Theme.subtext; elide: Text.ElideRight; Layout.fillWidth: true; renderType: Text.NativeRendering }
            }
            Repeater {
                model: [{ g: 0xF04AE, a: "prev" }, { g: 0xF040A, a: "toggle" }, { g: 0xF04AD, a: "next" }]
                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                    color: tr.containsMouse ? Theme.tileHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: Theme.g(parent.modelData.a === "toggle" && mainPage.cc.player && mainPage.cc.player.isPlaying ? 0xF03E4 : parent.modelData.g)
                        font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.text; renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: tr
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!mainPage.cc.player) return
                            if (modelData.a === "prev") mainPage.cc.player.previous()
                            else if (modelData.a === "next") mainPage.cc.player.next()
                            else mainPage.cc.player.togglePlaying()
                        }
                    }
                }
            }
        }
    }

    // Power profile and keyboard lighting live in gn-sense (also on the keyboard's N key).
    Tile {
        width: mainPage.span(6)
        glyph: Theme.g(0xF030C); title: "GN Sense"; sub: "Power · RGB"
        onClicked: { Ui.island = false; Ui.sh(Quickshell.env("HOME") + "/.local/bin/gn-sense") }
    }
    Tile {
        width: mainPage.span(6); glyph: Theme.g(0xF033E); title: "Lock"
        onClicked: { Ui.island = false; Ui.sh(Theme.scripts + "lock.sh") }
    }

    // session: first click arms the tile ("Confirm?"), second click within 3 s runs it
    Repeater {
        model: [
            { k: "logout",   g: 0xF08B, t: "Logout",   c: "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
            { k: "reboot",   g: 0xF021, t: "Restart",  c: "systemctl reboot" },
            { k: "poweroff", g: 0xF011, t: "Shutdown", c: "systemctl poweroff" }
        ]
        delegate: Tile {
            required property var modelData
            width: mainPage.span(4); compact: true
            glyph: Theme.g(modelData.g); title: mainPage.cc.armed === modelData.k ? "Confirm?" : modelData.t
            on: mainPage.cc.armed === modelData.k; onColor: Theme.red
            onClicked: {
                if (mainPage.cc.armed === modelData.k) { mainPage.cc.armed = ""; Ui.island = false; Ui.sh(modelData.c) }
                else { mainPage.cc.armed = modelData.k; mainPage.cc.armLater() }
            }
        }
    }
}
