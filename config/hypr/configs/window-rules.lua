return function(context)
    local HOME = context.home

    hl.window_rule({ name = "kitty-default-window", match = { class = "^kitty$" }, float = true, fullscreen = false, maximize = false, fullscreen_state = "0 0", size = { 960, 600 } })

    hl.window_rule({ match = { class = "^(osu!)$" }, tag = "+games" })
    hl.window_rule({ match = { class = "^([Cc]hatgpt)$" }, tag = "+projects", workspace = "1 silent" })

    hl.window_rule({
        match = {
            class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^(chrome-.+-Default)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^([Cc]hromium)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^(Brave-browser(-beta|-dev|-unstable)?)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^([Tt]horium-browser|[Cc]achy-browser)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^(zen-alpha|zen)$",
        },
        tag = "+browser",
    })

    hl.window_rule({
        match = {
            class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$",
        },
        tag = "+notif",
    })

    hl.window_rule({
        match = {
            title = "^(KooL Quick Cheat Sheet)$",
        },
        tag = "+KooL_Cheat",
    })

    hl.window_rule({
        match = {
            title = "^(KooL Hyprland Settings)$",
        },
        tag = "+KooL_Settings",
    })

    hl.window_rule({
        match = {
            class = "^(nwg-displays|nwg-look)$",
        },
        tag = "+KooL-Settings",
    })

    hl.window_rule({
        match = {
            class = "^(Alacritty|kitty|kitty-dropterm|ptyxis)$",
        },
        tag = "+terminal",
    })

    hl.window_rule({
        match = {
            class = "^([Tt]hunderbird|org.gnome.Evolution)$",
        },
        tag = "+email",
    })

    hl.window_rule({
        match = {
            class = "^(eu.betterbird.Betterbird)$",
        },
        tag = "+email",
    })

    hl.window_rule({
        match = {
            class = "^(codium|codium-url-handler|VSCodium)$",
        },
        tag = "+projects",
    })

    hl.window_rule({
        match = {
            class = "^(VSCode|code|code-url-handler)$",
        },
        tag = "+projects",
    })

    hl.window_rule({
        match = {
            class = "^(jetbrains-.+)$",
        },
        tag = "+projects",
    })

    hl.window_rule({
        match = {
            class = "^(clion|idea|pycharm|goland|webstorm|rider|datagrip|phpstorm)$",
        },
        tag = "+projects",
    })

    hl.window_rule({
        match = {
            class = "^(android-studio)$",
        },
        tag = "+projects",
    })

    hl.window_rule({
        match = {
            class = "^(com.obsproject.Studio)$",
        },
        tag = "+screenshare",
    })

    hl.window_rule({
        match = {
            class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^([Ff]erdium)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^([Ww]hatsapp-for-linux)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^(ZapZap|com.rtosta.zapzap)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^(teams-for-linux)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^(im.riot.Riot|Element)$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^([Ww]echat|[Qq][Qq])$",
        },
        tag = "+im",
    })

    hl.window_rule({
        match = {
            class = "^(fcitx5-remote)$",
        },
        stay_focused = true,
        float = true,
        min_size = "1 1",
        dim_around = true,
        border_size = 0,
        no_shadow = true,
        no_blur = true,
    })

    hl.window_rule({
        match = {
            class = "^(gamescope)$",
        },
        tag = "+games",
    })

    hl.window_rule({
        match = {
            class = "^(steam_app_\\d+)$",
        },
        tag = "+games",
    })

    hl.window_rule({
        match = {
            class = "^([Ss]team)$",
        },
        tag = "+gamestore",
    })

    hl.window_rule({
        match = {
            title = "^([Ll]utris)$",
        },
        tag = "+gamestore",
    })

    hl.window_rule({
        match = {
            class = "^(com.heroicgameslauncher.hgl)$",
        },
        tag = "+gamestore",
    })

    hl.window_rule({
        match = {
            class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$",
        },
        tag = "+file-manager",
    })

    hl.window_rule({
        match = {
            class = "^(app.drey.Warp)$",
        },
        tag = "+file-manager",
    })

    hl.window_rule({
        match = {
            class = "^([Ww]aytrogen)$",
        },
        tag = "+wallpaper",
    })

    hl.window_rule({
        match = {
            class = "^([Aa]udacious)$",
        },
        tag = "+multimedia",
    })

    hl.window_rule({
        match = {
            class = "^([Mm]pv|vlc)$",
        },
        tag = "+multimedia_video",
    })

    hl.window_rule({
        match = {
            title = "^(ROG Control)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(wihotspot(-gui)?)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^([Bb]aobab|org.gnome.[Bb]aobab)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(gnome-disks|wihotspot(-gui)?)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            title = "(Kvantum Manager)",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(file-roller|org.gnome.FileRoller)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(nm-applet|nm-connection-editor|blueman-manager)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(qt5ct|qt6ct|[Yy]ad)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "(xdg-desktop-portal-gtk)",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(org.kde.polkit-kde-authentication-agent-1)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^([Rr]ofi)$",
        },
        tag = "+settings",
    })

    hl.window_rule({
        match = {
            class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$",
        },
        tag = "+viewer",
    })

    hl.window_rule({
        match = {
            class = "^(evince)$",
        },
        tag = "+viewer",
    })

    hl.window_rule({
        match = {
            class = "^(eog|org.gnome.Loupe)$",
        },
        tag = "+viewer",
    })

    hl.window_rule({
        match = {
            tag = "multimedia_video*",
        },
        no_blur = true,
        opacity = 1.0,
    })

    hl.window_rule({
        match = {
            class = "^(Snipaste)$",
        },
        no_anim = true,
        no_blur = true,
        no_shadow = true,
        opacity = "1.0 override 1.0 override",
    })

    hl.window_rule({
        match = {
            tag = "KooL_Cheat*",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            class = "([Tt]hunar)",
            title = "negative:(.*[Tt]hunar.*)",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            title = "^(ROG Control)$",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            tag = "KooL-Settings*",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            title = "^(Keybindings)$",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            class = "^([Ff]erdium)$",
        },
        center = true,
    })

    hl.window_rule({
        match = {
            title = "^(Picture-in-Picture)$",
        },
        move = "72% 7%",
    })

    hl.window_rule({
        match = {
            title = "^(Firefox)$",
        },
        move = "72% 7%",
    })

    hl.window_rule({
        match = {
            fullscreen = 1,
        },
        idle_inhibit = "fullscreen",
    })

    hl.window_rule({
        match = {
            tag = "browser*",
        },
        workspace = "2",
    })

    hl.window_rule({
        match = {
            tag = "im*",
        },
        workspace = "4",
    })

    hl.window_rule({
        match = {
            tag = "gamestore*",
        },
        workspace = "5",
    })

    hl.window_rule({
        match = {
            tag = "games*",
        },
        workspace = "6",
    })

    hl.window_rule({
        match = {
            tag = "screenshare*",
        },
        workspace = "4 silent",
    })

    hl.window_rule({
        match = {
            class = "^(virt-manager)$",
        },
        workspace = "6 silent",
    })

    hl.window_rule({
        match = {
            class = "^(.virt-manager-wrapped)$",
        },
        workspace = "6 silent",
    })

    hl.window_rule({
        match = {
            tag = "multimedia*",
        },
        workspace = "9 silent",
    })

    hl.window_rule({
        match = {
            tag = "KooL_Cheat*",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            tag = "wallpaper*",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            tag = "settings*",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            tag = "viewer*",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            tag = "KooL-Settings*",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "([Zz]oom|onedriver|onedriver-launcher)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "(org.gnome.Calculator)",
            title = "(Calculator)",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "^(mpv|com.github.rafostar.Clapper)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "^([Qq]alculate-gtk)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "^([Ff]erdium)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            title = "^(Picture-in-Picture)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            title = "^(Authentication Required)$",
        },
        float = true,
        center = true,
    })

    hl.window_rule({
        match = {
            class = "(codium|codium-url-handler|VSCodium)",
            title = "negative:(.*codium.*|.*VSCodium.*)",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "^(com.heroicgameslauncher.hgl)$",
            title = "negative:(Heroic Games Launcher)",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "^([Ss]team)$",
            title = "negative:^([Ss]team)$",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            class = "([Tt]hunar)",
            title = "negative:(.*[Tt]hunar.*)",
        },
        float = true,
    })

    hl.window_rule({
        match = {
            title = "^(Add Folder to Workspace)$",
        },
        float = true,
        size = "70% 60%",
        center = true,
    })

    hl.window_rule({
        match = {
            title = "^(Save As)$",
        },
        float = true,
        size = "70% 60%",
        center = true,
    })

    hl.window_rule({
        match = {
            initial_title = "(Open Files)",
        },
        float = true,
        size = "70% 60%",
    })

    hl.window_rule({
        match = {
            title = "^(SDDM Background)$",
        },
        float = true,
        center = true,
        size = "16% 12%",
    })

    hl.window_rule({
        match = {
            tag = "browser*",
        },
        opacity = "1 override 0.95 override 1 override",
    })

    hl.window_rule({
        match = {
            tag = "projects*",
        },
        opacity = "1 override 0.95 override 1 override",
    })

    hl.window_rule({
        match = {
            tag = "im*",
        },
        opacity = "0.9 override 0.8 override",
    })

    hl.window_rule({
        match = {
            tag = "multimedia*",
        },
        opacity = "0.95 override 0.8 override",
    })

    hl.window_rule({
        match = {
            tag = "file-manager*",
        },
        opacity = "0.9 override 0.8 override",
    })

    hl.window_rule({
        match = {
            tag = "terminal*",
        },
        opacity = "1 override 0.95 override 1 override",
    })

    hl.window_rule({
        match = {
            tag = "settings*",
        },
        opacity = "0.8 override 0.7 override",
    })

    hl.window_rule({
        match = {
            tag = "viewer*",
        },
        opacity = "0.82 override 0.75 override",
    })

    hl.window_rule({
        match = {
            tag = "wallpaper*",
        },
        opacity = "0.9 override 0.7 override",
    })

    hl.window_rule({
        match = {
            class = "^(gedit|org.gnome.TextEditor|mousepad)$",
        },
        opacity = "0.8 override 0.7 override",
    })

    hl.window_rule({
        match = {
            class = "^(deluge)$",
        },
        opacity = "0.9 override 0.8 override",
    })

    hl.window_rule({
        match = {
            class = "^(seahorse)$",
        },
        opacity = "0.9 override 0.8 override",
    })

    hl.window_rule({
        match = {
            title = "^(Picture-in-Picture)$",
        },
        opacity = "0.95 override 0.75 override",
    })

    hl.window_rule({
        match = {
            tag = "KooL_Cheat*",
        },
        size = "65% 90%",
    })

    hl.window_rule({
        match = {
            tag = "wallpaper*",
        },
        size = "70% 70%",
    })

    hl.window_rule({
        match = {
            tag = "settings*",
        },
        size = "70% 70%",
    })

    hl.window_rule({
        match = {
            class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$",
        },
        size = "60% 70%",
    })

    hl.window_rule({
        match = {
            class = "^([Ff]erdium)$",
        },
        size = "60% 70%",
    })

    hl.window_rule({
        match = {
            title = "^(Picture-in-Picture)$",
        },
        pin = true,
    })

    hl.window_rule({
        match = {
            title = "^(Picture-in-Picture)$",
        },
        keep_aspect_ratio = true,
    })

    hl.window_rule({
        match = {
            tag = "games*",
        },
        no_blur = true,
        fullscreen = true,
    })

    hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5, dim_around = true })
    hl.layer_rule({ match = { namespace = "^(notifications|swaync-control-center|swaync-notification-window)$" }, blur = true, ignore_alpha = 0.5 })
    hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.5 })
    hl.layer_rule({ match = { namespace = "quickshell:control-center" }, blur = true, ignore_alpha = 0.45 })
    hl.layer_rule({ match = { namespace = "quickshell:osd" }, blur = true, no_anim = true })

    hl.window_rule({
        match = {
            class = "^(firefox|chromium|code)$",
        },
        animation = "popin 80%",
    })

    hl.window_rule({
        match = {
            class = "^(thunar|nautilus)$",
        },
        animation = "slide",
    })

    hl.window_rule({
        match = {
            workspace = "special:minimized",
        },
        animation = "slide",
        opacity = 0.8,
    })

    hl.window_rule({
        match = { tag = "calm-drag" },
        dim_around = true,
        no_shadow = true,
        border_size = 5,
        border_color = {
            colors = { "rgba(7cace4ff)", "rgba(e9b0d8ff)", "rgba(f6f6f4ff)" },
            angle = 45,
        },
        rounding = 20,
    })

    hl.layer_rule({ match = { namespace = "^(special:minimized)$" }, no_anim = true })
end
