return function(context)
    local HOME = context.home
    local UserScripts = context.user_scripts
    local scriptsDir = context.scripts

    hl.on("hyprland.start", function()
        hl.exec_cmd(UserScripts .. "/WallpaperSessionStart.sh")
        hl.exec_cmd("python3 " .. scriptsDir .. "/calm_drag.py")
        hl.exec_cmd(scriptsDir .. "/SessionRestore.sh delayed 1 &")
    end)
    hl.exec_cmd(scriptsDir .. "/GameMode.sh apply")
end
