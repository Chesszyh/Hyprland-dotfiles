return function(context)
    local HOME = context.home
    local color0, color10, color12, color15 = context.colors.color0, context.colors.color10, context.colors.color12, context.colors.color15
    local function read_theme_state(name)
        local file = io.open(HOME .. "/.local/state/dark-angel/" .. name, "r")
        if not file then return nil end
        local value = file:read("*l")
        file:close()
        return value
    end
    local shader_state = read_theme_state("screen-shader")
    local shader_enabled = shader_state == "on" or (shader_state == nil and read_theme_state("current") ~= "light")

    hl.config({
        general = {
            border_size = 2,
            gaps_in = 5,
            gaps_out = 10,
            col = {
                active_border = {
                    colors = { "rgba(ff1e3cee)", "rgba(8e001d88)", "rgba(19050acc)" },
                    angle = 45,
                },
                inactive_border = "rgba(250710aa)",
            },
            resize_on_border = true,
            layout = "dwindle",
        },
        decoration = {
            screen_shader = shader_enabled and (HOME .. "/.config/hypr/shaders/abyss_vignette.frag") or "",
            rounding = 12,
            active_opacity = 1.0,
            inactive_opacity = 0.92,
            fullscreen_opacity = 1.0,
            dim_inactive = true,
            dim_strength = 0.06,
            dim_special = 0.8,
            shadow = {
                enabled = true,
                range = 24,
                render_power = 3,
                color = "rgba(000000a6)",
                color_inactive = "rgba(00000070)",
            },
            blur = {
                enabled = true,
                size = 7,
                passes = 3,
                noise = 0.015,
                vibrancy = 0.2,
                ignore_opacity = true,
                new_optimizations = true,
                special = true,
                popups = true,
            },
        },
        group = {
            col = {
                border_active = color15,
            },
            groupbar = {
                col = {
                    active = color0,
                },
            },
        },
        animations = {
            enabled = true,
        },
        dwindle = {
            preserve_split = true,
            special_scale_factor = 0.8,
        },
        master = {
            new_status = "master",
            new_on_top = 1,
            mfact = 0.5,
        },
        input = {
            kb_layout = "us",
            kb_variant = "",
            kb_model = "",
            kb_options = "",
            kb_rules = "",
            repeat_rate = 50,
            repeat_delay = 300,
            sensitivity = 0.3, --mouse sensitivity
            numlock_by_default = true,
            left_handed = false,
            follow_mouse = 1,
            float_switch_override_focus = false,
            touchpad = {
                disable_while_typing = true,
                natural_scroll = true,
                clickfinger_behavior = false,
                middle_button_emulation = false,
                tap_to_click = true,
                drag_lock = false,
            },
            touchdevice = {
                enabled = true,
            },
            tablet = {
                transform = 0,
                left_handed = 0,
            },
        },
        misc = {
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            vrr = 2,
            mouse_move_enables_dpms = true,
            enable_swallow = false,
            swallow_regex = "^(kitty)$",
            focus_on_activate = false,
            initial_workspace_tracking = 0,
            middle_click_paste = false,
            enable_anr_dialog = true, -- Application not Responding (ANR)
            anr_missed_pings = 15, -- ANR Threshold default 1 is too low
        },
    })


    hl.device({ name = "elan06fa:00-04f3:327e-touchpad", enabled = true })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace",
    })
    hl.gesture({
        fingers = 3,
        direction = "up",
        action = "fullscreen",
    })
    hl.gesture({
        fingers = 3,
        direction = "down",
        action = "close",
    })
end
