import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

Scope {
    id: controlScope

    property string systemSummary: "CPU --  RAM --  BAT --"
    property string hostName: "localhost"
    property var clipboardEntries: []

    function execCommand(command, closePanel) {
        Hyprland.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(command)})`)
        if (closePanel)
            GlobalStates.controlCenterOpen = false
    }

    function run(command) {
        execCommand(command, true)
    }

    function runPinned(command) {
        execCommand(command, false)
    }

    function refreshSystem() {
        systemProbe.running = false
        systemProbe.command = ["bash", "-lc", "read _ u1 n1 s1 i1 rest < /proc/stat; t1=$((u1+n1+s1+i1)); sleep 0.18; read _ u2 n2 s2 i2 rest < /proc/stat; t2=$((u2+n2+s2+i2)); dt=$((t2-t1)); di=$((i2-i1)); cpu=0; [ \"$dt\" -gt 0 ] && cpu=$((100*(dt-di)/dt)); ram=$(free -m | awk '/Mem:/ { printf \"%d/%dM\", $3, $2 }'); bat=$(for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] && printf \"%s%% %s\" \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\")\" && exit; done; printf \"AC\"); printf \"CPU %s%%  RAM %s  BAT %s\\n\" \"$cpu\" \"$ram\" \"$bat\""]
        systemProbe.running = true
    }

    function refreshClipboard() {
        clipboardProbe.running = false
        clipboardProbe.command = ["bash", "-lc", "command -v cliphist >/dev/null || { echo 'cliphist unavailable'; exit 0; }; cliphist list | sed -E 's/\\x1b\\[[0-9;]*m//g' | head -n 5 | cut -c1-90"]
        clipboardProbe.running = true
    }

    function refreshHostName() {
        hostProbe.running = false
        hostProbe.command = ["bash", "-lc", "hostnamectl --static 2>/dev/null || hostname"]
        hostProbe.running = true
    }

    Component.onCompleted: {
        refreshHostName()
        refreshSystem()
        refreshClipboard()
    }

    Timer {
        interval: 3500
        repeat: true
        running: true
        onTriggered: {
            if (GlobalStates.controlCenterOpen) {
                controlScope.refreshSystem()
                controlScope.refreshClipboard()
            }
        }
    }

    Process {
        id: systemProbe
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim().length > 0)
                    controlScope.systemSummary = text.trim()
            }
        }
    }

    Process {
        id: hostProbe
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const name = text.trim()
                if (name.length > 0)
                    controlScope.hostName = name
            }
        }
    }

    Process {
        id: clipboardProbe
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(entry => entry.length > 0)
                controlScope.clipboardEntries = lines.length > 0 ? lines : ["No clipboard history"]
            }
        }
    }

    IpcHandler {
        target: "controlCenter"

        function toggle(): void {
            GlobalStates.controlCenterOpen = !GlobalStates.controlCenterOpen
        }

        function open(): void {
            GlobalStates.controlCenterOpen = true
            controlScope.refreshSystem()
            controlScope.refreshClipboard()
        }

        function close(): void {
            GlobalStates.controlCenterOpen = false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            screen: modelData
            visible: GlobalStates.controlCenterOpen
            color: "transparent"

            WlrLayershell.namespace: "quickshell:control-center"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                right: true
                bottom: true
            }

            readonly property int panelMargin: 18
            readonly property int panelWidth: Math.min(440, Math.max(390, root.screen.width * 0.30))

            implicitWidth: panelWidth + panelMargin * 2

            Rectangle {
                width: root.panelWidth
                height: Math.min(root.height - 36, content.implicitHeight + 28)
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 18
                anchors.rightMargin: root.panelMargin
                radius: Appearance.rounding.verylarge
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.24)
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 16
                    contentWidth: width
                    contentHeight: content.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: content
                        width: parent.width
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: controlScope.hostName
                            color: Appearance.m3colors.m3surfaceText
                            font.family: Appearance.font.family.uiFont
                            font.pixelSize: Appearance.font.pixelSize.textLarge
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: controlScope.systemSummary
                            color: Appearance.m3colors.m3secondaryText
                            font.family: Appearance.font.family.codeFont
                            font.pixelSize: Appearance.font.pixelSize.textSmall
                            elide: Text.ElideRight
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 10
                            Layout.fillWidth: true

                            ControlTile { label: "Ashen"; icon: "󰖨"; command: "qs ipc call theme switchTo light" }
                            ControlTile { label: "Abyss"; icon: "󰖔"; command: "qs ipc call theme switchTo dark" }
                            ControlTile { label: "Audio"; icon: ""; command: "pavucontrol" }
                            ControlTile { label: "Network"; icon: "󰤨"; command: "nm-connection-editor" }
                            ControlTile { label: "Bluetooth"; icon: "󰂯"; command: "blueman-manager" }
                            ControlTile { label: "Wallpaper"; icon: "󰸉"; command: "$HOME/.config/hypr/UserScripts/WallpaperSelect.sh" }
                            ControlTile { label: "Power"; icon: "󰐥"; command: "$HOME/.config/hypr/scripts/Wlogout.sh" }
                            ControlTile { label: "Close"; icon: "󰅖"; command: "qs ipc call controlCenter close" }
                        }

                        Section {
                            title: "Media"
                            body: ColumnLayout {
                                spacing: 8
                                Text {
                                    visible: Mpris.players.values.length === 0
                                    text: "No active MPRIS player"
                                    color: Appearance.m3colors.m3secondaryText
                                    font.family: Appearance.font.family.uiFont
                                    font.pixelSize: Appearance.font.pixelSize.textSmall
                                }
                                Repeater {
                                    model: Mpris.players.values
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        radius: Appearance.rounding.normal
                                        color: Appearance.colors.colLayer1
                                        border.width: 1
                                        border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.48)
                                        implicitHeight: mediaLayout.implicitHeight + 18

                                        ColumnLayout {
                                            id: mediaLayout
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 8

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.trackTitle || modelData.identity || "Unknown track"
                                                color: Appearance.m3colors.m3surfaceText
                                                elide: Text.ElideRight
                                                font.family: Appearance.font.family.uiFont
                                                font.pixelSize: Appearance.font.pixelSize.textBase
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.trackArtist || modelData.identity || "MPRIS"
                                                color: Appearance.m3colors.m3secondaryText
                                                elide: Text.ElideRight
                                                font.family: Appearance.font.family.uiFont
                                                font.pixelSize: Appearance.font.pixelSize.textSmall
                                            }

                                            RowLayout {
                                                spacing: 8
                                                MiniButton { label: "󰒮"; onPressed: modelData.previous() }
                                                MiniButton { label: modelData.isPlaying ? "󰏤" : "󰐊"; onPressed: modelData.togglePlaying() }
                                                MiniButton { label: "󰒭"; onPressed: modelData.next() }
                                                MiniButton { label: "󰐥"; onPressed: modelData.stop() }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            title: "Clipboard"
                            body: ColumnLayout {
                                spacing: 6
                                Repeater {
                                    model: controlScope.clipboardEntries
                                    delegate: Text {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        text: modelData
                                        color: Appearance.m3colors.m3secondaryText
                                        elide: Text.ElideRight
                                        font.family: Appearance.font.family.uiFont
                                        font.pixelSize: Appearance.font.pixelSize.textSmall
                                    }
                                }
                                ActionButton {
                                    label: "Open clipboard picker"
                                    command: "$HOME/.config/hypr/scripts/ClipManager.sh"
                                }
                            }
                        }

                        Section {
                            title: "Notifications"
                            body: GridLayout {
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                ActionButton { label: "Toggle center"; command: "swaync-client -t -sw"; closeOnClick: false }
                                ActionButton { label: "DND"; command: "swaync-client -d -sw"; closeOnClick: false }
                                ActionButton { label: "Clear"; command: "swaync-client -C"; closeOnClick: false }
                                ActionButton { label: "Reload"; command: "swaync-client --reload-config"; closeOnClick: false }
                            }
                        }

                    }
                }
            }
        }
    }

    component Section: ColumnLayout {
        required property string title
        required property Component body

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: title
            color: Appearance.m3colors.m3surfaceText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textMedium
            font.weight: Font.Bold
        }

        Loader {
            Layout.fillWidth: true
            sourceComponent: body
        }
    }

    component ControlTile: Rectangle {
        required property string label
        required property string icon
        required property string command

        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: 76
        radius: Appearance.rounding.normal
        color: mouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.44)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: icon
                color: Appearance.m3colors.m3accentPrimary
                font.family: Appearance.font.family.iconFont
                font.pixelSize: 22
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                Layout.maximumWidth: parent.parent.width - 16
                text: label
                color: Appearance.m3colors.m3surfaceText
                font.family: Appearance.font.family.uiFont
                font.pixelSize: Appearance.font.pixelSize.textSmall
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: controlScope.run(parent.command)
        }
    }

    component MiniButton: Rectangle {
        required property string label
        signal pressed()

        Layout.preferredWidth: 38
        Layout.preferredHeight: 32
        radius: Appearance.rounding.small
        color: miniMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.50)

        Text {
            anchors.centerIn: parent
            text: label
            color: Appearance.m3colors.m3accentPrimary
            font.family: Appearance.font.family.iconFont
            font.pixelSize: 16
        }

        MouseArea {
            id: miniMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.pressed()
        }
    }

    component ActionButton: Rectangle {
        required property string label
        required property string command
        property bool closeOnClick: true

        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: 36
        radius: Appearance.rounding.small
        color: actionMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.44)

        Text {
            anchors.centerIn: parent
            width: parent.width - 16
            text: label
            color: Appearance.m3colors.m3surfaceText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textSmall
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: controlScope.execCommand(parent.command, parent.closeOnClick)
        }
    }

}
