import QtQuick
import QtQuick.Layouts

// Control center sound page: output and input devices.
ColumnLayout {
    id: page
    required property var cc
    spacing: 8
    PageHeader { title: "Sound"; onBack: page.cc.goMain() }
    Text { text: "OUTPUT"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.subtext; renderType: Text.NativeRendering }
    Repeater {
        model: page.cc.sinks
        delegate: PickRow {
            required property var modelData
            title: modelData.desc; current: modelData.name === page.cc.defSink
            onPicked: { page.cc.defSink = modelData.name; Ui.sh("pactl set-default-sink '" + modelData.name + "'"); afterSet.restart() }
        }
    }
    Text { text: "INPUT"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.subtext; Layout.topMargin: 6; renderType: Text.NativeRendering }
    Text { visible: page.cc.sources.length === 0; text: "No microphone detected"; font.family: Theme.font; font.pixelSize: 12; color: Theme.subtext; renderType: Text.NativeRendering }
    Repeater {
        model: page.cc.sources
        delegate: PickRow {
            required property var modelData
            title: modelData.desc; current: modelData.name === page.cc.defSource
            onPicked: { page.cc.defSource = modelData.name; Ui.sh("pactl set-default-source '" + modelData.name + "'"); afterSet.restart() }
        }
    }
    PickRow { title: "Advanced mixer…"; onPicked: { Ui.cc = false; Ui.sh("pavucontrol") } }
}
