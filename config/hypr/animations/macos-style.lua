
hl.curve("macosEaseInOut", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
hl.curve("macosGenie", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1 } } })
hl.curve("macosSpring", { type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } })
hl.curve("macosSmooth", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
hl.curve("macosDock", { type = "bezier", points = { { 0.5, 1.5 }, { 0.5, 1 } } })
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 8,
    bezier = "macosSpring",
    style = "popin 50%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 12,
    bezier = "macosGenie",
    style = "popin 95%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6,
    bezier = "macosSmooth",
    style = "slide",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 10,
    bezier = "macosDock",
    style = "slidevert",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 8,
    bezier = "macosEaseInOut",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 10,
    bezier = "macosGenie",
})
hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 6,
    bezier = "macosSmooth",
})
hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 6,
    bezier = "macosEaseInOut",
})
hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 8,
    bezier = "macosEaseInOut",
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 6,
    bezier = "macosEaseInOut",
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 10,
    bezier = "macosGenie",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 8,
    bezier = "macosSmooth",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "macosSpring",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 10,
    bezier = "macosSpring",
    style = "once",
})
hl.config({
    animations = {
        enabled = true,
    },
})
