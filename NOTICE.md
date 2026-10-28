# 来源与许可

这是多个配置组件的集合。根目录 [MIT 许可证](LICENSE) 适用于独立原创内容，包括安装工具、项目文档、编辑器设置示例、统一配色系统与原创 Dark Angel 主题。它不替代以下组件的许可。

| 路径 | 来源 | 适用许可 |
| --- | --- | --- |
| `config/hypr/`、`config/waybar/`、`config/rofi/`、`config/swaync/`、`config/wallust/`、`config/wlogout/` | [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)，包含本项目修改 | [GPLv3](LICENSES/JaKooLit-LICENSE.md)；文件中已有的其他许可、来源与署名保留 |
| `config/quickshell/` | 基于 [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) 的组件，包含本项目修改 | [GPLv3](LICENSES/GPL-3.0.txt) |
| `config/quickshell/modules/common/functions/levendist.js` | [koeqaife/hyprland-material-you](https://github.com/koeqaife/hyprland-material-you)，来源说明保留在文件开头 | GPLv3 |
| `config/quickshell/modules/common/functions/fuzzysort.js` | [farzher/fuzzysort](https://github.com/farzher/fuzzysort)，Stephen Kamenar | [MIT](LICENSES/fuzzysort-MIT.txt) |
| `config/nvim/` | [ayamir/nvimdots](https://github.com/ayamir/nvimdots)，包含本项目修改 | [BSD 3-Clause](config/nvim/LICENSE) |
| `config/kitty/kitty-themes/` 中的第三方主题 | [dexpota/kitty-themes](https://github.com/dexpota/kitty-themes)，经 JaKooLit 配置使用 | [MIT](LICENSES/kitty-themes-MIT.txt)，保留文件内署名 |
| `config/kitty/kitty.conf` 与配色选择集成 | 基于 JaKooLit 配置的定制 | GPLv3；独立原创 `DarkAngel.conf` 与会话脚本使用根目录 MIT |
| `config/waybar/packaging/` | [Waybar](https://github.com/Alexays/Waybar)、[Fedora 打包源](https://src.fedoraproject.org/rpms/waybar/tree/f43) 及本项目补丁 | [Waybar MIT](LICENSES/Waybar-MIT.txt)，保留 Fedora 补丁作者信息 |
| `config/hypr/shaders/abyss_vignette.frag`、`config/kitty/kitty-themes/DarkAngel.conf` | 独立原创 Dark Angel 着色器与终端配色 | MIT，作为上述目录级许可的例外 |
| `config/dark-angel/`、`config/fontconfig/`、`config/zed/`、`config/systemd/`、`examples/`、`tools/`、`tests/`、项目文档 | 本项目独立配置、主题与工具 | MIT |

Hyprland 动画预设及原脚本保留了 END-4、HyDE、ML4W、JaKooLit 等来源标记。SwayNC 和 wlogout 图标取自 JaKooLit 的配置资源，没有包含个人壁纸或桌宠素材。

`config/hypr/UserScripts/Weather.py` 保留了最初 Waybar 集成的 JaKooLit / Surendrajat 来源说明。天气来自 [Open-Meteo](https://open-meteo.com/)，显示数据来源和更新时间；仓库不打包天气数据。

发行版软件包、Neovim 插件、字体、GTK/Qt 主题和可选应用各自保留其许可证；本仓库不分发它们的程序或字体文件。
