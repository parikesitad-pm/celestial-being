import QtQuick
import QtQuick.Layouts

// Collapsed island: date and time, focus countdown, CPU, RAM, GPU.
RowLayout {
    id: row
    property bool narrow: false
    property bool spread: false   // open header: clock left, stats pushed right
    spacing: 12

    // Fixed character count (monospace font), so a changing digit count doesn't resize the island.
    function pad(v, n) { return String(v).padStart(n, " ") }

    component Glyph: Text {
        font.family: Theme.iconFont
        font.pixelSize: 15
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
    }
    component Label: Text {
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
    }
    component Sep: Rectangle { implicitWidth: 1; implicitHeight: 14; color: Theme.stroke }

    Label { text: Qt.formatDateTime(Ui.now, row.narrow ? "HH:mm" : "ddd d MMM  HH:mm") }
    Item { visible: row.spread; Layout.fillWidth: true }

    Sep { visible: Agenda.focusEnd > 0 }
    RowLayout {
        spacing: 5
        visible: Agenda.focusEnd > 0
        Glyph { text: Theme.g(0xF051B); color: Theme.gold }
        Label { text: Ui.mmss(Agenda.focusLeft) }
    }

    Sep {}
    RowLayout {
        spacing: 5
        Glyph { text: Theme.g(0xF0EE0); color: Theme.accent }
        Label { text: row.pad(Ui.cpu, 3) + "%" }
    }
    RowLayout {
        spacing: 5
        Glyph { text: Theme.g(0xF035B); color: Theme.gold }
        Label { text: row.pad(Ui.mem, 4) + "G" }
    }
    RowLayout {
        spacing: 5
        visible: Ui.igpu >= 0 || Ui.gpu >= 0
        Glyph { text: Theme.g(0xF08AE); color: Theme.orange }
        Label {
            text: [Ui.igpu >= 0 ? "iGPU" + row.pad(Ui.igpu, 3) + "%" : "",
                   Ui.gpu >= 0 ? "dGPU" + row.pad(Ui.gpu, 3) + "%" : ""].filter(Boolean).join("  ")
        }
    }
}
