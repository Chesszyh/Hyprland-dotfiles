import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral"

    readonly property color toneColor: tone === "good" ? Appearance.m3colors.m3accentPrimary
        : tone === "warning" ? "#C77700"
        : tone === "error" ? "#BA1A1A"
        : Appearance.m3colors.m3secondaryText

    implicitWidth: Math.min(chipText.implicitWidth + 18, 260)
    implicitHeight: 24
    radius: Appearance.rounding.full
    color: ColorUtils.transparentize(toneColor, 0.86)
    border.width: 1
    border.color: ColorUtils.transparentize(toneColor, 0.36)

    Text {
        id: chipText
        anchors.centerIn: parent
        width: parent.width - 18
        text: root.text
        color: root.toneColor
        font.family: Appearance.font.family.uiFont
        font.pixelSize: Appearance.font.pixelSize.textSmall
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        maximumLineCount: 1
        clip: true
    }
}
