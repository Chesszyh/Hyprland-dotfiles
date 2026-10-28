import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string body: ""
    property string status: ""
    property string statusTone: "neutral"
    property var actions: []

    signal actionRequested(var action)

    Layout.fillWidth: true
    implicitHeight: cardLayout.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: cardMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
    border.width: 1
    border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.48)

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Appearance.m3colors.m3surfaceText
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textBase
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Appearance.m3colors.m3secondaryText
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            StatusChip {
                visible: root.status.length > 0
                text: root.status
                tone: root.statusTone
                Layout.alignment: Qt.AlignTop
            }
        }

        Text {
            visible: root.body.length > 0
            Layout.fillWidth: true
            text: root.body
            color: Appearance.m3colors.m3secondaryText
            font.family: Appearance.font.family.codeFont
            font.pixelSize: Appearance.font.pixelSize.textSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Flow {
            visible: root.actions.length > 0
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.actions

                WorkbenchButton {
                    required property var modelData
                    text: modelData.label || modelData.text || ""
                    icon: modelData.icon || ""
                    enabled: modelData.enabled !== false
                    onTriggered: root.actionRequested(modelData)
                }
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
