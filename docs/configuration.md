# 配置入口

安装后的路径是 `~/.config/` 加上组件目录名。仓库中的同名文件用于分享初始配置。

| 修改内容 | 文件 |
| --- | --- |
| 主题颜色 | `dark-angel/palette.json` |
| 窗口布局、输入、透明度 | `hypr/configs/settings.lua` |
| 应用规则、工作区 | `hypr/configs/window-rules.lua` |
| 快捷键 | `hypr/configs/keybinds.lua` |
| 默认应用 | `hypr/UserConfigs/defaults.lua` |
| 显示器 | `hypr/monitors.lua`；`Monitor_Profiles/` 是可选预设 |
| 动画 | `hypr/UserConfigs/UserAnimations.lua`、`hypr/animations/` |
| 顶栏布局 | `waybar/config` 指向的布局文件 |
| 深浅主题样式 | `waybar/style/dark-angel-abyss.css`、`dark-angel-ashen.css` |
| 启动器与剪贴板 | `rofi/config*.rasi`、`rofi/themes/` |
| 工作台数据范围 | `quickshell/config/workbench.json` |
| 字体 | `kitty/kitty.conf`、`quickshell/config.json`、`fontconfig/conf.d/50-user.conf`、编辑器设置 |

工作台的 `repo_roots` 与 `ssh_hosts` 默认为空。需要仓库状态或远程主机入口时，自行填写；不会随配置发布个人仓库和机器列表。

## 主题与初始状态

安装全部组件时会运行 `dark-angel/scripts/apply-theme.py dark`，生成主题颜色和缓存文件。单独安装 Hyprland 或 Quickshell 时，也需要安装 `dark-angel` 并运行该生成器：

```sh
python3 ~/.config/dark-angel/scripts/apply-theme.py dark
```

日常切换用 `hypr/UserScripts/DarkAngelTheme.sh`，它会同步主题文件并重载桌面。只有需要修改源配色时才编辑 `palette.json`；`~/.local/state/dark-angel` 下是生成结果和用户选择。

## 可选集成

- `waybar/UserModules` 定义的 `custom/codexbar` 需要自行安装 `codexbar` 并配置个人账号；不使用时从 Waybar 布局移除该模块。
- `custom/cava_mviz` 需要 cava；不使用时从布局移除。
- Daktilo 音效需要可用的 Daktilo 程序、对应音频预设与服务。`DAKTILO_BIN` 可指定程序路径。
- Neovim 需要按 [nvimdots](https://github.com/ayamir/nvimdots) 的依赖要求安装插件和语言工具；`lazy-lock.json` 固定插件版本。AI 相关功能使用用户自行配置的 CLI 或环境变量，不包含凭据。
- Zed 配置只包含字体与主题，附带 Dark Angel 主题文件。VS Code 示例只包含可合并的字体与配色项。
- GTK/Qt 主题、光标、输入法、外屏亮度和个人应用快捷键按本机情况调整。仓库不安装 WhiteSur、Bibata、Fcitx5 或默认应用。

## Waybar 与 Hyprland

`packaging/waybar-lua-workspaces.patch` 针对 Waybar 0.15.0，将工作区点击切换到 Lua 分发接口。打包说明位于 [Waybar packaging](../config/waybar/packaging/README.md)。更新后核对工作区事件连接，并实际测试点击与快捷键切换时的高亮。

已观察到 Waybar 重载时子进程在 Hyprland IPC 析构路径退出异常，主进程可继续运行。该现象尚未定位，不能将这里的配置测试理解为已解决这一问题。

## 验证范围

自动测试覆盖配置复制与备份、生成主题、Lua 入口加载、天气失败和缓存处理、会话脚本及工作台数据逻辑。Lua 入口测试使用接口桩检查加载依赖，不替代真实 compositor（显示合成器）的运行验证。

当前机器已有桌面外观与交互使用记录；公开快照还需要用户在新会话中确认显示器、工作区、托盘、锁屏与字体。安装测试在新的临时用户目录中执行，没有替换当前桌面配置；没有完成第二台机器或 Fedora 45 的验证。
