import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string tone: "warning"

    readonly property color toneColor: tone === "error" ? "#BA1A1A" : "#C77700"

    visible: text.length > 0
    Layout.fillWidth: true
    implicitHeight: Math.max(44, bannerText.implicitHeight + 20)
    radius: Appearance.rounding.normal
    color: ColorUtils.transparentize(toneColor, 0.88)
    border.width: 1
    border.color: ColorUtils.transparentize(toneColor, 0.32)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: root.tone === "error" ? "󰅙" : "󰀦"
            color: root.toneColor
            font.family: Appearance.font.family.iconFont
            font.pixelSize: 20
            Layout.alignment: Qt.AlignTop
        }

        Text {
            id: bannerText
            Layout.fillWidth: true
            text: root.text
            color: Appearance.m3colors.m3surfaceText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textSmall
            wrapMode: Text.WordWrap
        }
    }
}
