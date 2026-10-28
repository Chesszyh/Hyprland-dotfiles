import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property list<string> tabs: []

    spacing: 8

    Repeater {
        model: root.tabs

        delegate: Rectangle {
            required property string modelData
            readonly property bool selected: GlobalStates.workbenchTab === modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: Appearance.rounding.normal
            color: selected ? Appearance.colors.colLayer2Active : tabMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
            border.width: 1
            border.color: selected ? Appearance.m3colors.m3accentPrimary : ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.50)

            Text {
                anchors.centerIn: parent
                text: modelData
                color: selected ? Appearance.m3colors.m3surfaceText : Appearance.m3colors.m3secondaryText
                font.family: Appearance.font.family.uiFont
                font.pixelSize: Appearance.font.pixelSize.textSmall
                font.weight: selected ? Font.Bold : Font.DemiBold
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    GlobalStates.workbenchTab = parent.modelData
                    GlobalStates.workbenchSelectedIndex = 0
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
