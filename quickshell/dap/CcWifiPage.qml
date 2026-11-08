import QtQuick
import QtQuick.Layouts

// Control center Wi-Fi page: networks, password entry, rescan.
ColumnLayout {
    id: page
    required property var cc
    spacing: 8
    PageHeader { title: "Wi-Fi"; busy: page.cc.scanning || page.cc.wifiBusy; onBack: page.cc.goMain() }
    Text { visible: !page.cc.wifiOn || page.cc.nets.length === 0
           text: !page.cc.wifiOn ? "Wi-Fi is off. Turn it on from the main page." : (page.cc.scanning ? "Scanning…" : "No networks found")
           font.family: Theme.font; font.pixelSize: 12; color: Theme.subtext; Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering }
    // A failed join on a saved network has no password row to show the error in.
    Text { visible: page.cc.wifiMsg !== "" && page.cc.pwdFor === ""; text: page.cc.wifiMsg; color: Theme.red; font.family: Theme.font; font.pixelSize: 11
           Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering }
    Repeater {
        model: page.cc.wifiOn ? page.cc.nets : []
        delegate: ColumnLayout {
            id: nrow
            required property var modelData
            Layout.fillWidth: true; spacing: 6
            readonly property bool known: page.cc.saved.indexOf(modelData.ssid) >= 0
            readonly property bool asking: page.cc.pwdFor === modelData.ssid
            PickRow {
                title: nrow.modelData.ssid
                sub: page.cc.wifiBusy && page.cc.connectingTo === nrow.modelData.ssid ? "Connecting…"
                     : nrow.modelData.signal + "%" + (nrow.modelData.secure ? "  " + Theme.g(0xF033E) : "")
                current: nrow.modelData.active
                onPicked: {
                    if (page.cc.wifiBusy || nrow.modelData.active) return
                    page.cc.wifiMsg = ""
                    if (nrow.known || !nrow.modelData.secure) { page.cc.pwdFor = ""; page.cc.connectWifi(nrow.modelData.ssid, "") }
                    else { page.cc.pwdFor = nrow.asking ? "" : nrow.modelData.ssid; if (page.cc.pwdFor !== "") pw.forceActiveFocus(); else page.cc.refocus() }
                }
            }
            Rectangle {
                visible: nrow.asking
                Layout.fillWidth: true; implicitHeight: 44; radius: 14
                onVisibleChanged: if (!visible) pw.text = ""
                color: Theme.tile; border.width: 1; border.color: pw.activeFocus ? Theme.accent : Theme.stroke
                RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 6; spacing: 8
                    TextInput {
                        id: pw
                        Layout.fillWidth: true
                        echoMode: TextInput.Password; passwordCharacter: "•"
                        font.family: Theme.font; font.pixelSize: 13; color: Theme.text
                        renderType: Text.NativeRendering
                        selectByMouse: true; clip: true
                        enabled: !page.cc.wifiBusy
                        Text { visible: pw.text === ""; text: "Password"; font: pw.font; color: Theme.subtext; renderType: Text.NativeRendering }
                        Keys.onReturnPressed: if (text.length >= 8) page.cc.connectWifi(nrow.modelData.ssid, text)
                        Keys.onEscapePressed: { page.cc.pwdFor = ""; page.cc.refocus() }
                    }
                    Rectangle {
                        Layout.preferredWidth: 72; Layout.preferredHeight: 32; radius: 16
                        color: pw.text.length >= 8 && !page.cc.wifiBusy ? Theme.accent : Theme.tile
                        Text { anchors.centerIn: parent; text: page.cc.wifiBusy ? "…" : "Join"; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                               color: pw.text.length >= 8 && !page.cc.wifiBusy ? Theme.onTint : Theme.subtext; renderType: Text.NativeRendering }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (pw.text.length >= 8 && !page.cc.wifiBusy) page.cc.connectWifi(nrow.modelData.ssid, pw.text) }
                    }
                }
            }
            Text { visible: nrow.asking && page.cc.wifiMsg !== ""; text: page.cc.wifiMsg; color: Theme.red; font.family: Theme.font; font.pixelSize: 11
                   Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering }
        }
    }
    PickRow { title: "Rescan"; sub: page.cc.scanning ? "Scanning…" : ""; onPicked: page.cc.scanWifi() }
    PickRow { title: "Advanced settings…"; onPicked: { Ui.cc = false; Ui.sh("nm-connection-editor") } }
}
