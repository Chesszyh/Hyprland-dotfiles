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
    readonly property var groups: groupItems(items)

    function clipText(value, limit) {
        const text = value === undefined || value === null ? "" : String(value)
        if (text.length <= limit)
            return text
        return text.slice(0, Math.max(0, limit - 3)) + "..."
    }

    function groupItems(items) {
        const dirty = []
        const clean = []
        const other = []
        for (const item of items) {
            if (item.clean === false || Number(item.dirty_count || 0) > 0)
                dirty.push(item)
            else if (item.clean === true)
                clean.push(item)
            else
                other.push(item)
        }
        const groups = []
        if (dirty.length > 0)
            groups.push({ "title": "Dirty", "tone": "warning", "items": dirty })
        if (clean.length > 0)
            groups.push({ "title": "Clean", "tone": "good", "items": clean })
        if (other.length > 0)
            groups.push({ "title": "Other", "tone": "neutral", "items": other })
        return groups
    }

    function repoTitle(item, index) {
        return clipText(item.name || item.path || ("Repository " + (index + 1)), 96)
    }

    function repoSubtitle(item) {
        const branch = item.branch || "unknown branch"
        const upstream = item.upstream ? (" -> " + item.upstream) : ""
        return clipText(branch + upstream, 120)
    }

    function repoBody(item) {
        const dirty = Number(item.dirty_count || 0)
        const ahead = Number(item.ahead || 0)
        const behind = Number(item.behind || 0)
        const path = item.path || "unknown path"
        return clipText("dirty " + dirty + " / ahead " + ahead + " / behind " + behind + "\n" + path, 320)
    }

    function repoStatus(item) {
        const dirty = Number(item.dirty_count || 0)
        if (dirty > 0)
            return dirty + " dirty"
        if (item.clean === true)
            return "clean"
        return "unknown"
    }

    function repoStatusTone(item) {
        if (Number(item.dirty_count || 0) > 0 || item.clean === false)
            return "warning"
        if (item.clean === true)
            return "good"
        return "neutral"
    }

    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 14

        Text {
            visible: root.items.length === 0
            Layout.fillWidth: true
            text: "No repositories returned"
            color: Appearance.m3colors.m3secondaryText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textBase
            horizontalAlignment: Text.AlignHCenter
            topPadding: 48
        }

        Repeater {
            model: root.groups

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: Appearance.m3colors.m3surfaceText
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: Appearance.font.pixelSize.textBase
                        font.weight: Font.Bold
                    }

                    StatusChip {
                        text: modelData.items.length + " repos"
                        tone: modelData.tone
                    }
                }

                Repeater {
                    model: modelData.items

                    EntityCard {
                        required property var modelData
                        required property int index
                        title: root.repoTitle(modelData, index)
                        subtitle: root.repoSubtitle(modelData)
                        body: root.repoBody(modelData)
                        status: root.repoStatus(modelData)
                        statusTone: root.repoStatusTone(modelData)
                    }
                }
            }
        }
    }
}
