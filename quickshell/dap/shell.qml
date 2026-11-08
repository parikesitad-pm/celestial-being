//@ pragma UseQApplication
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants { model: Ui.barScreens; SideBar {} }
    Calendar {}
    Island {}
    Launcher {}
    VolumeOsd {}
    Variants { model: Quickshell.screens; Overview {} }
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
        // 0 Haro (music), 1 Mission (calendar), 2 Sortie (focus), 3 Orders (todo), 4 Comms (notifications), 5 Veda (system), 6 Hangar (apps)
        function tab(i: int): void { Ui.openIsland(i) }
        function power(): void { Ui.openSheet("launch") }
        function bridge(): void { Ui.openSheet("bridge") }
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
