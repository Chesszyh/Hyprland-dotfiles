-- Abyssal Ritual Curves
hl.curve("abyssSettle", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("abyssDissolve", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.curve("abyssMist", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- Legacy curves for compatibility
hl.curve("macosEaseInOut", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
hl.curve("macosGenie", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1 } } })
hl.curve("macosSpring", { type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } })
hl.curve("macosSmooth", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
hl.curve("macosDock", { type = "bezier", points = { { 0.5, 1.5 }, { 0.5, 1 } } })

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 6,
    bezier = "abyssSettle",
    style = "popin 88%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 7,
    bezier = "abyssDissolve",
    style = "popin 92%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6,
    bezier = "abyssSettle",
    style = "slide",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 7,
    bezier = "abyssSettle",
    style = "slidevert",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 6,
    bezier = "abyssMist",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 7,
    bezier = "abyssDissolve",
})
hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 7,
    bezier = "abyssMist",
})
hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 6,
    bezier = "abyssMist",
})
hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 7,
    bezier = "abyssMist",
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 6,
    bezier = "abyssMist",
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 7,
    bezier = "abyssDissolve",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "abyssSettle",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 7,
    bezier = "abyssSettle",
})
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 100,
    bezier = "linear",
    style = "loop",
})
hl.config({
    animations = {
        enabled = true,
    },
})
