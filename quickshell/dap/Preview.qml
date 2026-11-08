import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Quick Look panel for Dolphin, opened by hypr/scripts/preview.sh.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: Ui.preview || card.opacity > 0.01
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.preview ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int textLimit: 65536
    readonly property string path: Ui.previewPath
    readonly property string name: path.slice(path.lastIndexOf("/") + 1)
    readonly property bool isImage: Ui.previewKind === "image"
    // Nothing stays decoded or in memory once the panel has closed.
    readonly property bool loaded: Ui.preview || card.opacity > 0.01

    function sizeLabel(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1048576) return Math.round(bytes / 1024) + " KB"
        return (bytes / 1048576).toFixed(1) + " MB"
    }
    function openInApp() {
        Quickshell.execDetached(["xdg-open", path])
        Ui.preview = false
    }

    Process {
        id: reader
        command: ["head", "-c", String(win.textLimit), win.path]
        running: Ui.preview && !win.isImage
        stdout: StdioCollector { onStreamFinished: body.text = text }
    }
    onLoadedChanged: if (!loaded) body.text = ""

    MouseArea { anchors.fill: parent; onClicked: Ui.preview = false }

    Rectangle {
        id: card
        width: Math.min(900, parent.width - 48)
        height: Math.min(640, parent.height - 120)
        anchors.centerIn: parent
        radius: 28
        color: Theme.glassStrong
        border.width: 1; border.color: Theme.stroke
        opacity: Ui.preview ? 1 : 0
        scale: Ui.preview ? 1 : 0.96
        focus: Ui.preview
        Behavior on opacity { NumberAnimation { duration: Ui.preview ? 180 : 120; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Ui.preview ? 240 : 140; easing.type: Easing.OutExpo } }
        MouseArea { anchors.fill: parent }   // swallow clicks

        Keys.onEscapePressed: Ui.preview = false
        Keys.onSpacePressed: Ui.preview = false
        Keys.onReturnPressed: win.openInApp()
        Keys.onEnterPressed: win.openInApp()

        Item {
            id: header
            x: 24; y: 14; width: parent.width - 48; height: 48
            Column {
                anchors { left: parent.left; right: openButton.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                Text { width: parent.width; text: win.name; elide: Text.ElideMiddle; color: Theme.text
                       font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { text: win.sizeLabel(Ui.previewSize) + (!win.isImage && Ui.previewSize > win.textLimit ? " · showing the first " + win.sizeLabel(win.textLimit) : "")
                       color: Theme.subtext; font.family: Theme.font; font.pixelSize: 11 }
            }
            Rectangle {
                id: openButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: openLabel.implicitWidth + 24; height: 32; radius: 10
                color: openArea.containsMouse ? Theme.tileHover : Theme.tile
                Text { id: openLabel; anchors.centerIn: parent; text: "Open"; color: Theme.text
                       font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
                MouseArea { id: openArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.openInApp() }
            }
        }
        Rectangle { x: 20; y: 70; width: parent.width - 40; height: 1; color: Theme.stroke }

        Item {
            id: content
            x: 20; y: 82; width: parent.width - 40; height: parent.height - 102
            clip: true

            Image {
                id: picture
                anchors.fill: parent
                visible: win.isImage
                source: win.loaded && win.isImage ? "file://" + encodeURI(win.path).replace(/#/g, "%23").replace(/\?/g, "%3F") : ""
                sourceSize: Qt.size(content.width, content.height)
                fillMode: Image.PreserveAspectFit
                asynchronous: true; cache: false; smooth: true
            }
            Text {
                anchors.centerIn: parent
                visible: win.isImage && picture.status === Image.Error
                text: "Can't preview this image. Press Enter to open it."
                color: Theme.subtext; font.family: Theme.font; font.pixelSize: 14
            }
            Flickable {
                id: textView
                anchors.fill: parent
                visible: !win.isImage
                contentHeight: body.paintedHeight
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: body
                    width: textView.width
                    readOnly: true; activeFocusOnPress: false; selectByMouse: false
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.WrapAnywhere
                    color: Theme.text; font.family: Theme.font; font.pixelSize: 13
                }
            }
        }
    }
}
