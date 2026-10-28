pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string gen_cache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    
    // Other dirs used by the shell, without "file://"
    property string homePath: FileUtils.trimFileProtocol(Directories.home)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/quickshell`)
    property string shellConfigPath: `${Directories.shellConfig}/config.json`
    property string darkAngelState: `${Directories.homePath}/.local/state/dark-angel`
    property string generatedMaterialThemePath: `${Directories.darkAngelState}/qml_color.json`
}
