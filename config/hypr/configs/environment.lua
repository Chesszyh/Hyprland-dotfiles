return function(context)
    local HOME = context.home

    hl.env("GTK_THEME", "WhiteSur-Dark")
    hl.env("GTK2_RC_FILES", HOME .. "/.gtkrc-2.0")

    hl.env("GTK_USE_PORTAL", "1")

    hl.env("GDK_BACKEND", "wayland,x11,*")
    hl.env("QT_QPA_PLATFORM", "wayland;xcb")
    hl.env("CLUTTER_BACKEND", "wayland")

    hl.env("GTK_IM_MODULE", "fcitx")
    hl.env("QT_IM_MODULE", "fcitx")
    hl.env("XMODIFIERS", "@im=fcitx")
    hl.env("INPUT_METHOD", "fcitx")
    hl.env("GLFW_IM_MODULE", "ibus")

    hl.env("XDG_CONFIG_HOME", HOME .. "/.config")
    hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_TYPE", "wayland")

    hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
    hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
    hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

    hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

    hl.env("XDG_STATE_HOME", HOME .. "/.local/state")
    hl.env("HYPRLAND_LOG_WLR", "1")

    hl.env("GDK_SCALE", "1")
    hl.env("QT_SCALE_FACTOR", "1")

    hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
    hl.env("HYPRCURSOR_SIZE", "24")

    hl.env("MOZ_ENABLE_WAYLAND", "1")

    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

    hl.env("GSK_RENDERER", "ngl")
end
