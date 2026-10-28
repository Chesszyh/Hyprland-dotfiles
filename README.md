# Dark Angel Dotfiles

Fedora / Hyprland 桌面配置，使用黑红色的 Dark Angel 主题，包含深浅主题切换、窗口动画、工作区面板、概览、控制中心、锁屏、终端和编辑器配置。

所有组件放在一个仓库，目录结构对应 `~/.config/`。安装工具会备份已有组件，并生成主题所需的初始状态文件。

## 包含内容

| 目录 | 功能 |
| --- | --- |
| `config/hypr` | Lua 窗口管理配置、动画、着色器、快捷键、会话与壁纸脚本 |
| `config/waybar` | 工作区、天气、托盘、系统状态和深浅主题；附 Fedora RPM 构建输入 |
| `config/quickshell` | 桌面概览、控制中心、屏幕提示和工作台 |
| `config/rofi`、`config/swaync`、`config/wlogout` | 启动器、剪贴板选择、通知中心和电源菜单 |
| `config/dark-angel`、`config/wallust` | 统一主题色与壁纸取色模板 |
| `config/kitty`、`config/nvim`、`config/zed` | 终端、Neovim 与 Zed 的配置和主题 |
| `config/fontconfig` | 霞鹜文楷界面字体与独立的等宽代码字体 |
| `examples/editor-settings/vscode.json` | 可合并到 VS Code 用户设置中的字体与配色项 |
| `config/systemd` | 桌面面板用户服务配置 |

## 环境与依赖

Hyprland 需要支持 `hl.*` Lua 配置接口。整理基于 Fedora 43 和 Hyprland 0.56.2 的实际使用环境；普通的旧版 Hyprlang 配置接口不能直接加载这里的 `hyprland.lua`。Fedora 45 尚未验证。

主要组件：Waybar、Quickshell（`qs`）、Rofi、SwayNC、wlogout、hyprlock、hypridle、Kitty、Neovim、Python 3、Bash、Lua、jq、libnotify、UWSM（Universal Wayland Session Manager，会话管理器）。

配套工具包括 `wl-clipboard`、cliphist、grim、slurp、swappy、playerctl、pamixer、brightnessctl、awww、mpvpaper、ffmpeg、ImageMagick 和 Wallust。按使用的功能安装；外屏亮度使用 ddcutil，输入法使用 Fcitx5。Waybar 的音乐可视化、用量模块、打字音效和工作台中的开发工具属于可选集成，见[配置说明](docs/configuration.md)。

字体不随仓库分发。界面使用 LXGW WenKai，Kitty 使用 FantasqueSansM Nerd Font Mono，VS Code 示例使用 IBM Plex Mono / Fira Code；其他图标需要 Nerd Fonts。可按本机字体修改对应配置。

## 安装

先安装所需桌面组件，在仓库根目录预览：

```sh
python3 tools/install.py --dry-run
```

安装全部组件，或只选择某些组件：

```sh
python3 tools/install.py --apply
python3 tools/install.py --component kitty --apply
```

已有组件目录会移动到 `~/.local/state/dark-angel-dotfiles/desktop-config-backup-*`。安装用户服务时只替换仓库提供的服务文件，保留其他应用的服务。VS Code 示例需要自行合并到用户设置；不会覆盖完整的 VS Code 配置。

安装工具只复制配置并生成初始主题，不安装软件包、不启停服务、不重载当前桌面。已有 Hyprland 会话中，确认配置与依赖就绪后运行：

```sh
systemctl --user daemon-reload
systemctl --user enable --now waybar.service swaync.service qs.service hypridle.service
systemctl --user enable --now hypridle-inhibit.service
hyprctl reload
hyprctl configerrors
```

首次启动前可编辑 `config/hypr/monitors.lua`，默认使用自动识别的显示器模式。默认应用在 `config/hypr/UserConfigs/defaults.lua`。壁纸不随仓库分发，通过壁纸菜单选择自己的图片或视频。

## 常用操作

| 操作 | 入口 |
| --- | --- |
| 常用快捷键 / 完整列表 | `Super+H` / `Super+Shift+K` |
| 控制中心 | `Super+X` |
| 切换主题 | Waybar 左侧主题按钮，或 `~/.config/hypr/UserScripts/DarkAngelTheme.sh toggle` |
| 开关暗角着色器 | `Super+Shift+V` |
| 自动锁屏 | 顶栏眼睛按钮；睁眼红色为禁止自动锁屏，闭眼恢复计时 |
| 注销菜单 | 顶栏电源按钮 |

开启 `hypridle-inhibit.service` 后，登录默认禁止自动锁屏；手动锁屏仍可使用。暗角的手动选择保留到下一次主题切换。

天气默认固定上海嘉定，每 15 分钟查询 Open-Meteo，提示中显示北京时间、单位与更新时间；失败时明确显示缓存状态。位置在 `config/hypr/UserScripts/Weather.py` 中修改。

## 检查与维护

```sh
python3 -m unittest discover -s tests
python3 -m unittest discover -s config/hypr/tests
python3 -m unittest discover -s config/quickshell/scripts -p 'test_*.py'
bash config/kitty/tests/test-kitty-session-scripts.sh
```

[配置说明](docs/configuration.md) 列出自定义入口、可选集成与验证边界。[Waybar 打包说明](config/waybar/packaging/README.md) 包含 Lua 工作区点击补丁和构建方法。

## 许可与来源

独立原创内容使用 [MIT](LICENSE)。JaKooLit / end-4 派生配置保留 GPLv3，Neovim 保留 BSD 3-Clause，其他第三方文件保留原许可与署名。完整对应关系见 [NOTICE](NOTICE.md)。
