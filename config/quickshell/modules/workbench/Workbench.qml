import "root:/"
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: workbenchScope

    property var tabData: ({
        "ok": true,
        "topic": GlobalStates.workbenchTab,
        "updated_at": "",
        "summary": {},
        "warnings": [],
        "items": []
    })
    property var searchData: ({
        "ok": true,
        "topic": "search",
        "updated_at": "",
        "summary": {},
        "warnings": [],
        "items": []
    })
    property string activeRequestTab: ""

    readonly property list<string> tabs: [
        "agents",
        "repos",
        "network",
        "runtime",
        "visual",
        "commands"
    ]

    function tabIndex(tab) {
        for (let i = 0; i < tabs.length; i++) {
            if (tabs[i] === tab)
                return i
        }
        return -1
    }

    function fallbackEnvelope(tab, warning) {
        return {
            "ok": false,
            "topic": tab,
            "updated_at": new Date().toISOString(),
            "summary": {},
            "warnings": [warning],
            "items": []
        }
    }

    function parseEnvelope(tab, text) {
        try {
            const parsed = JSON.parse(text)
            if (typeof parsed !== "object" || parsed === null)
                return fallbackEnvelope(tab, "workbench_data.py returned a non-object payload")
            if (!Array.isArray(parsed.warnings))
                parsed.warnings = []
            if (!Array.isArray(parsed.items))
                parsed.items = []
            if (typeof parsed.summary !== "object" || parsed.summary === null)
                parsed.summary = {}
            if (!parsed.topic)
                parsed.topic = tab
            return parsed
        } catch (error) {
            return fallbackEnvelope(tab, "Failed to parse workbench data: " + error)
        }
    }

    function refreshTab(tab) {
        if (tabIndex(tab) < 0)
            return
        if (!GlobalStates.workbenchOpen)
            return

        activeRequestTab = tab
        dataProcess.running = false
        dataProcess.command = [
            "python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/workbench_data.py",
            tab
        ]
        dataProcess.running = true
    }

    function stopRefresh() {
        activeRequestTab = ""
        dataProcess.running = false
    }

    function setTab(tab) {
        const index = tabIndex(tab)
        if (index < 0)
            return

        GlobalStates.workbenchTab = tabs[index]
        GlobalStates.workbenchSelectedIndex = 0
    }

    function nextTab() {
        const current = Math.max(0, tabIndex(GlobalStates.workbenchTab))
        setTab(tabs[(current + 1) % tabs.length])
    }

    function previousTab() {
        const current = Math.max(0, tabIndex(GlobalStates.workbenchTab))
        setTab(tabs[(current + tabs.length - 1) % tabs.length])
    }

    function open() {
        GlobalStates.workbenchOpen = true
    }

    function close() {
        GlobalStates.workbenchOpen = false
        stopRefresh()
    }

    function toggle() {
        GlobalStates.workbenchOpen = !GlobalStates.workbenchOpen
        if (!GlobalStates.workbenchOpen)
            stopRefresh()
    }

    Component.onCompleted: {
        if (GlobalStates.workbenchOpen)
            refreshTab(GlobalStates.workbenchTab)
    }

    Connections {
        target: GlobalStates

        function onWorkbenchOpenChanged() {
            if (GlobalStates.workbenchOpen)
                workbenchScope.refreshTab(GlobalStates.workbenchTab)
            else
                workbenchScope.stopRefresh()
        }

        function onWorkbenchTabChanged() {
            if (GlobalStates.workbenchOpen)
                workbenchScope.refreshTab(GlobalStates.workbenchTab)
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: GlobalStates.workbenchOpen
        onTriggered: workbenchScope.refreshTab(GlobalStates.workbenchTab)
    }

    Process {
        id: dataProcess

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const requestTab = workbenchScope.activeRequestTab
                if (!GlobalStates.workbenchOpen || requestTab.length === 0 || requestTab !== GlobalStates.workbenchTab)
                    return

                const envelope = workbenchScope.parseEnvelope(requestTab, text.trim())
                if (envelope.topic !== requestTab)
                    return

                if (envelope.topic === "search")
                    workbenchScope.searchData = envelope
                else
                    workbenchScope.tabData = envelope
            }
        }
    }

    IpcHandler {
        target: "workbench"

        function toggle(): void {
            workbenchScope.toggle()
        }

        function open(): void {
            workbenchScope.open()
        }

        function close(): void {
            workbenchScope.close()
        }

        function showTab(tab: string): void {
            workbenchScope.setTab(tab)
            workbenchScope.open()
        }
    }

    Variants {
        model: Quickshell.screens

        WorkbenchWindow {
            tabs: workbenchScope.tabs
            tabData: workbenchScope.tabData
            searchData: workbenchScope.searchData
            onNextTabRequested: workbenchScope.nextTab()
            onPreviousTabRequested: workbenchScope.previousTab()
        }
    }
}
