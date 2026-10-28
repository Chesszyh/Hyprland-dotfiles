import "root:/"
import "root:/modules/common"
import "components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    property var data: ({ "ok": true, "warnings": [], "items": [] })
    readonly property var items: Array.isArray(data.items) ? data.items : []
    readonly property var warnings: Array.isArray(data.warnings) ? data.warnings : []

    function clipText(value, limit) {
        const text = value === undefined || value === null ? "" : String(value)
        if (text.length <= limit)
            return text
        return text.slice(0, Math.max(0, limit - 3)) + "..."
    }

    function titleFor(item, index) {
        return clipText(item.name || item.label || item.path || ("Agent " + (index + 1)), 96)
    }

    function subtitleFor(item) {
        return clipText(item.kind || "agent", 80)
    }

    function bodyFor(item) {
        const details = []
        if (item.path)
            details.push(item.path)
        if (item.summary)
            details.push(item.summary)
        if (item.windows)
            details.push("windows " + item.windows)
        if (item.attached !== undefined && item.attached !== null)
            details.push("attached " + item.attached)
        if (details.length > 0)
            return clipText(details.join("\n"), 300)
        return clipText(JSON.stringify(item), 300)
    }

    function statusFor(item) {
        if (item.exists === true)
            return "found"
        if (item.exists === false)
            return "missing"
        if (item.attached === "1" || item.attached === 1)
            return "attached"
        return clipText(item.kind || "", 40)
    }

    function statusToneFor(item) {
        if (item.exists === true || item.attached === "1" || item.attached === 1)
            return "good"
        if (item.exists === false)
            return "warning"
        return "neutral"
    }

    function actionsFor(item) {
        if (item.kind === "session_root")
            return [{ "label": "Open path", "enabled": false }]
        if (item.kind === "tmux" || item.kind === "zellij")
            return [{ "label": "Attach", "enabled": false }]
        return []
    }

    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 10

        Repeater {
            model: root.warnings

            WarningBanner {
                required property string modelData
                text: root.clipText(modelData, 240)
                tone: root.data.ok === false ? "error" : "warning"
            }
        }

        Text {
            visible: root.items.length === 0
            Layout.fillWidth: true
            text: root.warnings.length > 0 ? "No agent items available" : "No agent items returned"
            color: Appearance.m3colors.m3secondaryText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textBase
            horizontalAlignment: Text.AlignHCenter
            topPadding: 48
        }

        Repeater {
            model: root.items

            EntityCard {
                required property var modelData
                required property int index
                title: root.titleFor(modelData, index)
                subtitle: root.subtitleFor(modelData)
                body: root.bodyFor(modelData)
                status: root.statusFor(modelData)
                statusTone: root.statusToneFor(modelData)
                actions: root.actionsFor(modelData)
            }
        }
    }
}
