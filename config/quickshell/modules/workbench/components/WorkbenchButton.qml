import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool enabled: true

    signal triggered()

    implicitWidth: Math.max(82, buttonContent.implicitWidth + 22)
    implicitHeight: 32
    radius: Appearance.rounding.small
    color: !enabled ? ColorUtils.transparentize(Appearance.colors.colLayer2, 0.38)
        : buttonMouse.pressed ? Appearance.colors.colLayer2Active
        : buttonMouse.containsMouse ? Appearance.colors.colLayer2Hover
        : Appearance.colors.colLayer2
    border.width: 1
    border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, enabled ? 0.42 : 0.68)
    opacity: enabled ? 1.0 : 0.56

    RowLayout {
        id: buttonContent
        anchors.centerIn: parent
        spacing: root.icon.length > 0 && root.text.length > 0 ? 7 : 0

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: Appearance.m3colors.m3accentPrimary
            font.family: Appearance.font.family.iconFont
            font.pixelSize: 18
        }

        Text {
            visible: root.text.length > 0
            text: root.text
            color: Appearance.m3colors.m3surfaceText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textSmall
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
