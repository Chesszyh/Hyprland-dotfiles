return function(context)
    local HOME = context.home
    local scriptsDir = context.scripts
    local UserScripts = context.user_scripts
    local mainMod = "SUPER"
    local defaults = context.defaults
    local term = defaults.terminal
    local files = defaults.files
    local UWSMAPP = scriptsDir .. "/UwsmApp.sh app"
    local DarkAngelTheme = UserScripts .. "/DarkAngelTheme.sh"

    hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(scriptsDir .. "/LogoutHook.sh && hyprctl dispatch 'hl.dsp.exit()'"), { description = "保存会话并注销" })
    hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "常用 / 关闭当前窗口" })
    hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"), { description = "强制结束当前窗口进程" })
    hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"), { description = "常用 / 锁屏" })
    hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "打开电源菜单" })
    hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "通知中心" })
    hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh"), { description = "桌面设置" })

    hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"), { description = "减少主区域窗口" })
    hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"), { description = "增加主区域窗口" })
    hl.bind(mainMod .. " + J", hl.dsp.window.cycle_next({ next = true }), { description = "常用 / 下一个窗口" })
    hl.bind(mainMod .. " + K", hl.dsp.window.cycle_next({ next = false }), { description = "常用 / 上一个窗口" })
    hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "与主窗口交换" })

    hl.bind(mainMod .. " + CTRL + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/Wake.sh"), { description = "恢复桌面显示" })

    hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "切换分割方向" })
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "切换伪平铺" })

    hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "切换窗口分组" })
    hl.bind(mainMod .. " + CTRL + tab", hl.dsp.group.next(), { description = "下一个组内窗口" })

    hl.bind("ALT + tab", hl.dsp.window.cycle_next({ next = true }), { description = "下一个窗口" })
    hl.bind("ALT + tab", hl.dsp.window.bring_to_top(), { description = "置顶当前浮动窗口" })

    hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { locked = true, repeating = true, description = "音量：增加" })
    hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { locked = true, repeating = true, description = "音量：降低" })
    hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true, description = "音量：麦克风静音" })
    hl.bind("xf86audiomute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { locked = true, description = "音量：静音" })
    hl.bind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "睡眠" })
    hl.bind("xf86Rfkill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { locked = true, description = "切换飞行模式" })

    hl.bind("xf86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "媒体播放：播放或暂停" })
    hl.bind("xf86AudioPlay", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "媒体播放：播放或暂停" })
    hl.bind("xf86AudioNext", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true, description = "媒体播放：下一首" })
    hl.bind("xf86AudioPrev", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true, description = "媒体播放：上一首" })
    hl.bind("xf86audiostop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true, description = "媒体播放：停止" })

    hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "常用 / 截图：选区" })
    hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --pin"), { description = "截图：选区并用 Swappy 编辑" })
    hl.bind("ALT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "截图：当前窗口" })
    hl.bind("CTRL + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --all"), { description = "截图：全部屏幕" })

    hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "向左调整窗口大小" })
    hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "向右调整窗口大小" })
    hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "向上调整窗口大小" })
    hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "向下调整窗口大小" })

    hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }), { description = "向左移动窗口" })
    hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }), { description = "向右移动窗口" })
    hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }), { description = "向上移动窗口" })
    hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }), { description = "向下移动窗口" })

    hl.bind(mainMod .. " + ALT + left", hl.dsp.window.swap({ direction = "l" }), { description = "向左交换窗口" })
    hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }), { description = "向右交换窗口" })
    hl.bind(mainMod .. " + ALT + up", hl.dsp.window.swap({ direction = "u" }), { description = "向上交换窗口" })
    hl.bind(mainMod .. " + ALT + down", hl.dsp.window.swap({ direction = "d" }), { description = "向下交换窗口" })

    hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "向左切换焦点" })
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "向右切换焦点" })
    hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "向上切换焦点" })
    hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "向下切换焦点" })

    hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }), { description = "切换到本屏下一工作区" })
    hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), { description = "切换到本屏上一工作区" })

    hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "移到临时工作区" })
    hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(""), { description = "显示或隐藏临时工作区" })


    hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 }), { description = "移到工作区 1" })
    hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 }), { description = "移到工作区 2" })
    hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 }), { description = "移到工作区 3" })
    hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 }), { description = "移到工作区 4" })
    hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 }), { description = "移到工作区 5" })
    hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 }), { description = "移到工作区 6" })
    hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 }), { description = "移到工作区 7" })
    hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 }), { description = "移到工作区 8" })
    hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 }), { description = "移到工作区 9" })
    hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }), { description = "移到工作区 10" })
    hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = -1 }), { description = "移到上一编号工作区" })
    hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), { description = "移到下一编号工作区" })

    hl.bind(mainMod .. " + CTRL + code:10", hl.dsp.window.move({ workspace = 1, follow = false }), { description = "移到工作区 1并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:11", hl.dsp.window.move({ workspace = 2, follow = false }), { description = "移到工作区 2并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:12", hl.dsp.window.move({ workspace = 3, follow = false }), { description = "移到工作区 3并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:13", hl.dsp.window.move({ workspace = 4, follow = false }), { description = "移到工作区 4并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:14", hl.dsp.window.move({ workspace = 5, follow = false }), { description = "移到工作区 5并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:15", hl.dsp.window.move({ workspace = 6, follow = false }), { description = "移到工作区 6并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:16", hl.dsp.window.move({ workspace = 7, follow = false }), { description = "移到工作区 7并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:17", hl.dsp.window.move({ workspace = 8, follow = false }), { description = "移到工作区 8并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:18", hl.dsp.window.move({ workspace = 9, follow = false }), { description = "移到工作区 9并保留焦点" })
    hl.bind(mainMod .. " + CTRL + code:19", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "移到工作区 10并保留焦点" })
    hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = -1, follow = false }), { description = "移到上一编号工作区并保留焦点" })
    hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "移到下一编号工作区并保留焦点" })

    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "切换到下一个已有工作区" })
    hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "切换到上一个已有工作区" })
    hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }), { description = "切换到下一个已有工作区" })
    hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "切换到上一个已有工作区" })

    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "拖动窗口" })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "鼠标调整窗口大小" })


    hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true, description = "键盘背光：降低" })
    hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true, description = "键盘背光：增加" })
    hl.bind("xf86Launch1", hl.dsp.exec_cmd("rog-control-center"), { description = "ASUS 控制面板" })
    hl.bind("xf86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"), { description = "ASUS 键盘灯光" })
    hl.bind("xf86Launch4", hl.dsp.exec_cmd("asusctl profile -n"), { description = "ASUS 性能模式" })
    hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessFocused.sh --dec"), { repeating = true, description = "当前屏幕亮度：降低" })
    hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessFocused.sh --inc"), { repeating = true, description = "当前屏幕亮度：增加" })
    hl.bind("xf86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"), { description = "切换触控板" })
    hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "截图：当前屏幕" })
    hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "截图：选区" })
    hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "截图：延迟 5 秒截取当前屏幕" })
    hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "截图：延迟 10 秒截取当前屏幕" })
    hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "截图：当前窗口" })

    hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && $HOME/.config/hypr/UserScripts/DarkAngelAppLauncher.py"), { description = "常用 / 应用启动器" })
    hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open \"https://\""), { description = "打开浏览器" })
    hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewToggle"), { description = "常用 / 窗口总览" })
    hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(UWSMAPP .. " " .. term), { description = "常用 / 打开终端" })
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(UWSMAPP .. " ratty"), { description = "打开 Ratty" })
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(UWSMAPP .. " " .. files), { description = "常用 / 文件管理器" })
    hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(UWSMAPP .. " code"), { description = "常用 / VS Code" })
    hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(UWSMAPP .. " flatpak run io.github.alainm23.planify"), { description = "Planify" })

    hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(scriptsDir .. "/MacOSMinimize.sh"), { description = "常用 / 最小化当前窗口" })
    hl.bind("ALT + M", hl.dsp.exec_cmd(scriptsDir .. "/MacOSRestore.sh"), { description = "常用 / 选择窗口并恢复到原工作区" })

    hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "常用快捷键" })
    hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"), { description = "刷新桌面面板" })
    hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"), { description = "表情符号" })
    hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"), { description = "网页搜索" })
    hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "切换模糊强度" })
    hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "常用 / 切换游戏模式" })
    hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"), { description = "切换平铺布局" })
    hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"), { description = "常用 / 剪贴板历史" })
    hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh"), { description = "Rofi 主题" })
    hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"), { description = "Rofi 主题选择器" })
    hl.bind(mainMod .. " + CTRL + SHIFT + C", hl.dsp.exec_cmd("$HOME/.codex/tools/codex-cache-miss-notifier-toggle"), { description = "切换 Codex 缓存提醒" })

    hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "切换全屏" })
    hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "切换最大化" })
    hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }), { description = "切换窗口浮动" })
    local allfloat_rules = {}
    local function toggle_allfloat()
        local workspace = hl.get_active_workspace()
        if not workspace then return end
        local rule = allfloat_rules[workspace.id]
        if rule then
            rule:set_enabled(not rule:is_enabled())
        else
            allfloat_rules[workspace.id] = hl.window_rule({
                name = "allfloat-" .. workspace.id,
                match = { workspace = workspace.id },
                float = true,
            })
        end
        for _, window in ipairs(workspace:get_windows()) do
            hl.dispatch(hl.dsp.window.float({ window = window, action = "toggle" }))
        end
    end

    hl.bind(mainMod .. " + ALT + SPACE", toggle_allfloat, { description = "切换当前工作区浮动" })
    hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh " .. term), { description = "常用 / 调出或收起终端" })

    hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.exec_cmd(scriptsDir .. "/Zoom.sh in"), { description = "桌面放大：放大" })
    hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.exec_cmd(scriptsDir .. "/Zoom.sh out"), { description = "桌面放大：缩小" })

    hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"), { description = "显示或隐藏状态栏" })
    hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"), { description = "状态栏样式" })
    hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "状态栏布局" })

    hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(UserScripts .. "/RofiBeats.sh"), { description = "背景音乐" })
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperSelect.sh"), { description = "常用 / 选择壁纸" })
    hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperModeToggle.sh"), { description = "静态或动态壁纸" })
    hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperVideoMuteToggle.sh"), { description = "动态壁纸静音" })
    hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperEffects.sh"), { description = "壁纸效果" })
    hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(UserScripts .. "/ScreenShaderToggle.sh"), { description = "常用 / 切换暗黑晕影着色器" })
    hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperRandom.sh"), { description = "随机壁纸" })
    hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "切换窗口不透明" })
    hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"), { description = "常用 / 搜索全部快捷键" })
    hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"), { description = "选择动画" })
    hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(UserScripts .. "/ZshChangeTheme.sh"), { description = "终端主题" })
    hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true, description = "切换键盘布局" })
    hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true, description = "切换窗口键盘布局" })
    hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh"), { description = "计算器" })
    hl.bind(mainMod .. " + CTRL + ALT + M", hl.dsp.exec_cmd(UserScripts .. "/DaktiloMuteToggle.sh"), { description = "切换打字音效" })
    hl.bind(mainMod .. " + CTRL + ALT + left", hl.dsp.exec_cmd(UserScripts .. "/DaktiloPresetSwitch.sh prev"), { description = "切换打字音效预设：上一个" })
    hl.bind(mainMod .. " + CTRL + ALT + right", hl.dsp.exec_cmd(UserScripts .. "/DaktiloPresetSwitch.sh next"), { description = "切换打字音效预设：下一个" })
    hl.bind(mainMod .. " + Escape", hl.dsp.focus({ last = true }), { description = "常用 / 返回上一窗口" })
    hl.bind(mainMod .. " + ALT + Q", hl.dsp.exec_cmd(scriptsDir .. "/FocusApp.py qq"), { description = "常用 / 聚焦 QQ" })
    hl.bind(mainMod .. " + ALT + A", hl.dsp.exec_cmd(scriptsDir .. "/FocusApp.py chatgpt"), { description = "常用 / 聚焦 Chatgpt 窗口" })

    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/SessionSave.sh manual"), { description = "常用 / 保存应用和工作区" })
    hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd(scriptsDir .. "/SessionRestore.sh restore"), { description = "常用 / 恢复应用和工作区" })
    hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd(scriptsDir .. "/SessionManager.sh"), { description = "会话管理" })

    hl.bind(mainMod .. " + ALT + F11", hl.dsp.exec_cmd(scriptsDir .. "/ExternalBrightness.sh --dec"), { locked = true, repeating = true, description = "外接屏亮度：降低" })
    hl.bind(mainMod .. " + ALT + F12", hl.dsp.exec_cmd(scriptsDir .. "/ExternalBrightness.sh --inc"), { locked = true, repeating = true, description = "外接屏亮度：增加" })

    hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("$HOME/.local/bin/tosu-overlay --toggle"), { description = "切换 osu! 数据面板" })


    hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(DarkAngelTheme .. " toggle"), { description = "切换浅色或深色主题" })
    hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(DarkAngelTheme .. " light"), { description = "浅色主题" })
    hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd(DarkAngelTheme .. " dark"), { description = "深色主题" })
    hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("qs ipc call controlCenter toggle"), { description = "常用 / 控制中心" })

    hl.bind("CTRL + ALT + Q", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/LogoutHook.sh && hyprctl dispatch 'hl.dsp.exit()'"), { description = "保存会话并注销" })

    hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }), { description = "切换到工作区 1" })
    hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }), { description = "切换到工作区 2" })
    hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }), { description = "切换到工作区 3" })
    hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }), { description = "切换到工作区 4" })
    hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }), { description = "切换到工作区 5" })
    hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }), { description = "切换到工作区 6" })
    hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }), { description = "切换到工作区 7" })
    hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }), { description = "切换到工作区 8" })
    hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }), { description = "切换到工作区 9" })
    hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "切换到工作区 10" })
end
