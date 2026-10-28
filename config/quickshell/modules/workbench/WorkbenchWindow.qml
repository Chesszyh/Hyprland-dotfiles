import "root:/"
import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property list<string> tabs: []
    property var tabData: ({ "ok": true, "topic": GlobalStates.workbenchTab, "summary": {}, "warnings": [], "items": [] })
    property var searchData: ({ "ok": true, "topic": "search", "summary": {}, "warnings": [], "items": [] })

    signal nextTabRequested()
    signal previousTabRequested()

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor.id
    readonly property var activeData: tabData || ({ "ok": false, "topic": GlobalStates.workbenchTab, "summary": {}, "warnings": ["No workbench data loaded"], "items": [] })
    readonly property var previewItems: Array.isArray(activeData.items) ? activeData.items.slice(0, 6) : []
    readonly property var warningMessages: Array.isArray(activeData.warnings) ? activeData.warnings.slice(0, 3) : []
    readonly property var summaryEntries: summaryToEntries(activeData.summary)

    function clipText(value, limit) {
        const text = value === undefined || value === null ? "" : String(value)
        if (text.length <= limit)
            return text
        return text.slice(0, Math.max(0, limit - 3)) + "..."
    }

    function summaryToEntries(summary) {
        if (typeof summary !== "object" || summary === null)
            return []
        return Object.keys(summary).map(key => ({
            "key": clipText(key, 28),
            "value": clipText(valueText(summary[key]), 96)
        }))
    }

    function valueText(value) {
        if (Array.isArray(value))
            return value.join(", ")
        if (typeof value === "object" && value !== null)
            return Object.keys(value).map(key => key + "=" + valueText(value[key])).join("  ")
        if (value === undefined || value === null)
            return "-"
        return String(value)
    }

    function itemTitle(item, index) {
        return clipText(item.name || item.label || item.host || item.path || item.id || ("Item " + (index + 1)), 96)
    }

    function itemSubtitle(item) {
        const parts = []
        if (item.kind)
            parts.push(item.kind)
        if (item.source_topic)
            parts.push(item.source_topic)
        if (item.branch)
            parts.push(item.branch)
        if (item.os)
            parts.push(item.os)
        if (item.category)
            parts.push(item.category)
        return clipText(parts.join(" / "), 120)
    }

    function itemStatus(item) {
        if (item.clean === true)
            return "clean"
        if (item.clean === false)
            return String(item.dirty_count || 0) + " dirty"
        if (item.online === true)
            return "online"
        if (item.online === false)
            return "offline"
        if (item.exists === true)
            return "found"
        if (item.exists === false)
            return "missing"
        if (item.status)
            return clipText(item.status, 40)
        return clipText(item.kind || "", 40)
    }

    function itemStatusTone(item) {
        if (item.clean === true || item.online === true || item.exists === true)
            return "good"
        if (item.clean === false || item.online === false || item.exists === false)
            return "warning"
        return "neutral"
    }

    function itemBody(item) {
        const fields = []
        if (item.path)
            fields.push(item.path)
        if (item.upstream)
            fields.push("upstream " + item.upstream)
        if (item.ahead || item.behind)
            fields.push("ahead " + (item.ahead || 0) + " / behind " + (item.behind || 0))
        if (Array.isArray(item.ips) && item.ips.length > 0)
            fields.push(item.ips.join(", "))
        if (item.command)
            fields.push(Array.isArray(item.command) ? item.command.join(" ") : String(item.command))
        if (item.process && item.process.cmdline)
            fields.push(item.process.cmdline)
        if (item.cwd)
            fields.push(item.cwd)
        if (fields.length > 0)
            return clipText(fields.join("\n"), 360)
        return clipText(JSON.stringify(item), 360)
    }

    screen: modelData
    visible: GlobalStates.workbenchOpen
    color: "transparent"

    WlrLayershell.namespace: "quickshell:workbench"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    mask: Region {
        item: GlobalStates.workbenchOpen ? panel : null
    }
    HyprlandWindow.visibleMask: Region {
        item: GlobalStates.workbenchOpen ? panel : null
    }

    HyprlandFocusGrab {
        id: grab
        windows: [ root ]
        property bool canBeActive: root.monitorIsFocused
        active: false
        onCleared: () => {
            if (!active)
                GlobalStates.workbenchOpen = false
        }
    }

    Connections {
        target: GlobalStates
        function onWorkbenchOpenChanged() {
            if (GlobalStates.workbenchOpen) {
                delayedGrabTimer.start()
                commandDeck.forceInputFocus()
            } else {
                grab.active = false
            }
        }
    }

    Timer {
        id: delayedGrabTimer
        interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            if (!grab.canBeActive)
                return
            grab.active = GlobalStates.workbenchOpen
            commandDeck.forceInputFocus()
        }
    }

    Rectangle {
        id: panel
        width: Math.max(320, Math.min(root.width - 64, 1120))
        height: Math.max(360, Math.min(root.height - 72, 700))
        anchors.centerIn: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.22)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            CommandDeck {
                id: commandDeck
                Layout.fillWidth: true
                tabs: root.tabs
                maxSelectedIndex: Math.max(0, root.previewItems.length - 1)
                onNextTabRequested: root.nextTabRequested()
                onPreviousTabRequested: root.previousTabRequested()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                WorkbenchTabs {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    tabs: root.tabs
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.50)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: root.activeData.topic || GlobalStates.workbenchTab
                                    color: Appearance.m3colors.m3surfaceText
                                    font.family: Appearance.font.family.uiFont
                                    font.pixelSize: Appearance.font.pixelSize.textLarge
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.activeData.updated_at ? ("Updated " + root.activeData.updated_at) : "Waiting for backend data"
                                    color: Appearance.m3colors.m3secondaryText
                                    font.family: Appearance.font.family.codeFont
                                    font.pixelSize: Appearance.font.pixelSize.textSmall
                                    elide: Text.ElideRight
                                }
                            }

                            StatusChip {
                                text: root.activeData.ok === false ? "warning" : (root.previewItems.length + " items")
                                tone: root.activeData.ok === false ? "warning" : "good"
                                Layout.alignment: Qt.AlignTop
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            visible: root.summaryEntries.length > 0
                            spacing: 8

                            Repeater {
                                model: root.summaryEntries

                                StatusChip {
                                    required property var modelData
                                    text: modelData.key + ": " + modelData.value
                                }
                            }
                        }

                        Repeater {
                            model: root.warningMessages

                            WarningBanner {
                                required property string modelData
                                text: root.clipText(modelData, 240)
                                tone: root.activeData.ok === false ? "error" : "warning"
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Query: " + (GlobalStates.workbenchQuery.length > 0 ? GlobalStates.workbenchQuery : "empty")
                            color: Appearance.m3colors.m3secondaryText
                            font.family: Appearance.font.family.codeFont
                            font.pixelSize: Appearance.font.pixelSize.textSmall
                            elide: Text.ElideRight
                        }

                        Loader {
                            id: tabLoader
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: GlobalStates.workbenchTab === "agents" ? agentTabComponent
                                : GlobalStates.workbenchTab === "repos" ? repoTabComponent
                                : genericTabComponent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Selected index: " + GlobalStates.workbenchSelectedIndex
                            color: Appearance.m3colors.m3secondaryText
                            font.family: Appearance.font.family.codeFont
                            font.pixelSize: Appearance.font.pixelSize.textSmall
                        }
                    }
                }
            }
        }
    }

    Component {
        id: genericTabComponent

        ScrollView {
            id: dataScroll
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: dataScroll.availableWidth
                spacing: 10

                Text {
                    visible: root.previewItems.length === 0
                    Layout.fillWidth: true
                    text: "No items returned for this topic"
                    color: Appearance.m3colors.m3secondaryText
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textBase
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 48
                }

                Repeater {
                    model: root.previewItems

                    EntityCard {
                        required property var modelData
                        required property int index
                        title: root.itemTitle(modelData, index)
                        subtitle: root.itemSubtitle(modelData)
                        body: root.itemBody(modelData)
                        status: root.itemStatus(modelData)
                        statusTone: root.itemStatusTone(modelData)
                    }
                }

                Text {
                    visible: Array.isArray(root.activeData.items) && root.activeData.items.length > root.previewItems.length
                    Layout.fillWidth: true
                    text: "+" + (root.activeData.items.length - root.previewItems.length) + " more"
                    color: Appearance.m3colors.m3secondaryText
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Component {
        id: agentTabComponent

        AgentTab {
            data: root.activeData
        }
    }

    Component {
        id: repoTabComponent

        RepoTab {
            data: root.activeData
        }
    }
}
