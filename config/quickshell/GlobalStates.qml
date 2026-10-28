import "root:/modules/common/"
import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool overviewOpen: false
    property bool controlCenterOpen: false
    property bool workbenchOpen: false
    property string workbenchTab: "agents"
    property string workbenchQuery: ""
    property int workbenchSelectedIndex: 0
    property bool osdVisible: false
    property string osdKind: "status"
    property string osdLabel: "Status"
    property real osdValue: 0
    property int osdSerial: 0
}
