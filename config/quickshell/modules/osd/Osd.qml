import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: osdScope

    function iconFor(kind) {
        if (kind === "volume") return ""
        if (kind === "brightness") return "󰃠"
        if (kind === "media") return "󰝚"
        return "󰀦"
    }

    IpcHandler {
        target: "osd"

        function setOsd(kind: string, value: real, label: string): void {
            GlobalStates.osdKind = kind
            GlobalStates.osdValue = Math.max(0, Math.min(100, value))
            GlobalStates.osdLabel = label || kind
            GlobalStates.osdVisible = true
            GlobalStates.osdSerial += 1
        }

        function showVolume(value: string): void {
            setOsd("volume", Number(value), "Volume")
        }

        function showBrightness(value: string): void {
            setOsd("brightness", Number(value), "Brightness")
        }

        function showMedia(label: string): void {
            setOsd("media", 100, label)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            screen: modelData
            visible: GlobalStates.osdVisible
            color: "transparent"

            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                left: true
                right: true
                bottom: true
            }

            implicitHeight: 150

            Connections {
                target: GlobalStates
                function onOsdSerialChanged() {
                    hideTimer.restart()
                }
            }

            Timer {
                id: hideTimer
                interval: 1300
                repeat: false
                onTriggered: GlobalStates.osdVisible = false
            }

            Rectangle {
                width: 420
                height: 86
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 38
                radius: Appearance.rounding.verylarge
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.25)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: osdScope.iconFor(GlobalStates.osdKind)
                            color: Appearance.m3colors.m3accentPrimary
                            font.family: Appearance.font.family.iconFont
                            font.pixelSize: 24
                        }

                        Text {
                            text: GlobalStates.osdLabel
                            color: Appearance.m3colors.m3surfaceText
                            font.family: Appearance.font.family.uiFont
                            font.pixelSize: Appearance.font.pixelSize.textMedium
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: `${Math.round(GlobalStates.osdValue)}%`
                            color: Appearance.m3colors.m3secondaryText
                            font.family: Appearance.font.family.codeFont
                            font.pixelSize: Appearance.font.pixelSize.textSmall
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 10
                        radius: 999
                        color: Appearance.colors.colLayer2

                        Rectangle {
                            width: parent.width * GlobalStates.osdValue / 100
                            height: parent.height
                            radius: parent.radius
                            color: Appearance.m3colors.m3accentPrimary
                            Behavior on width {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                    }
                }
            }
        }
    }
}
