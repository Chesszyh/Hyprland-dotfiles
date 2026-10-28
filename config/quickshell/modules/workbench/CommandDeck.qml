import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property list<string> tabs: []
    property int maxSelectedIndex: 0

    signal nextTabRequested()
    signal previousTabRequested()

    function forceInputFocus() {
        commandInput.forceActiveFocus()
    }

    Layout.preferredHeight: 64
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.44)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Text {
            text: "󰘳"
            color: Appearance.m3colors.m3accentPrimary
            font.family: Appearance.font.family.iconFont
            font.pixelSize: Appearance.font.pixelSize.iconLarge
            Layout.alignment: Qt.AlignVCenter
        }

        TextField {
            id: commandInput
            Layout.fillWidth: true
            focus: GlobalStates.workbenchOpen
            text: GlobalStates.workbenchQuery
            padding: 0
            renderType: Text.NativeRendering
            color: activeFocus ? Appearance.m3colors.m3surfaceText : Appearance.m3colors.m3secondaryText
            selectedTextColor: Appearance.m3colors.m3selectionText
            selectionColor: Appearance.m3colors.m3selectionBackground
            placeholderText: "Workbench command"
            placeholderTextColor: Appearance.m3colors.m3borderPrimary
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textBase
            background: null

            onTextChanged: {
                if (GlobalStates.workbenchQuery !== text)
                    GlobalStates.workbenchQuery = text
            }

            Connections {
                target: GlobalStates
                function onWorkbenchQueryChanged() {
                    if (commandInput.text !== GlobalStates.workbenchQuery)
                        commandInput.text = GlobalStates.workbenchQuery
                }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (commandInput.text.length > 0) {
                        commandInput.text = ""
                        GlobalStates.workbenchQuery = ""
                    } else {
                        GlobalStates.workbenchOpen = false
                    }
                    event.accepted = true
                    return
                }

                if (event.key === Qt.Key_Left) {
                    root.previousTabRequested()
                    event.accepted = true
                    return
                }

                if (event.key === Qt.Key_Right) {
                    root.nextTabRequested()
                    event.accepted = true
                    return
                }

                if (event.key === Qt.Key_Up) {
                    GlobalStates.workbenchSelectedIndex = Math.max(0, GlobalStates.workbenchSelectedIndex - 1)
                    event.accepted = true
                    return
                }

                if (event.key === Qt.Key_Down) {
                    GlobalStates.workbenchSelectedIndex = Math.min(root.maxSelectedIndex, GlobalStates.workbenchSelectedIndex + 1)
                    event.accepted = true
                }
            }

            cursorDelegate: Rectangle {
                width: 1
                color: commandInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                radius: 1
            }
        }

        Text {
            text: GlobalStates.workbenchTab
            color: Appearance.m3colors.m3secondaryText
            font.family: Appearance.font.family.codeFont
            font.pixelSize: Appearance.font.pixelSize.textSmall
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
