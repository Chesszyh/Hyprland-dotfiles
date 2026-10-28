import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root
    property string currentMode: "dark"
    property string scriptPath: Directories.shellConfig + "/scripts/dark-angel-theme.py"

    function runTheme(mode) {
        if (mode !== "light" && mode !== "dark" && mode !== "toggle") {
            return `invalid mode: ${mode}`
        }
        Hyprland.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(`'${scriptPath}' ${mode}`)})`)
        reloadTimer.restart()
        return mode
    }

    Timer {
        id: reloadTimer
        interval: 180
        repeat: false
        onTriggered: {
            MaterialThemeLoader.reapplyTheme()
        }
    }

    IpcHandler {
        target: "theme"

        function switchTo(mode: string): string {
            root.currentMode = mode
            return root.runTheme(mode)
        }

        function toggle(): string {
            root.currentMode = root.currentMode === "dark" ? "light" : "dark"
            return root.runTheme("toggle")
        }

        function current(): string {
            return root.currentMode
        }
    }
}
