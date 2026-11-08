//@ pragma UseQApplication
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants { model: Ui.barScreens; Bar {} }
    Calendar {}
    Island {}
    ControlCenter {}
    Launcher {}
    VolumeOsd {}
    Variants { model: Quickshell.screens; Overview {} }
    Dock {}
    Screenshot {}
    Preview {}

    IpcHandler {
        target: "shell"
        function launcher(): void { Ui.toggle("launcher") }
        function calendar(): void { Ui.toggle("calendar") }
        function notifs(): void {
            Ui.islandTab = 4
            if (!Ui.island) Ui.toggle("island")
        }
        function island(): void { Ui.toggle("island") }
        function cc(): void { Ui.toggle("cc") }
        function screenshot(): void { Ui.toggle("shot") }
        function overview(): void { Ui.toggle("overview") }
        function overviewOpen(): void { if (!Ui.overview) Ui.toggle("overview") }
        function overviewClose(): void { Ui.overview = false }
        function preview(kind: string, path: string, size: int): void {
            Ui.closeAll()
            Ui.previewKind = kind; Ui.previewPath = path; Ui.previewSize = size
            Ui.preview = true
        }
        function previewClose(): bool {
            const wasOpen = Ui.preview
            Ui.preview = false
            return wasOpen
        }
    }
}
