local HOME = os.getenv("HOME")
local root = HOME .. "/.config/hypr"
local colors = dofile(root .. "/wallust/colors.lua")
for name, value in pairs(dofile(HOME .. "/.local/state/dark-angel/hypr.lua")) do
    colors[name] = value
end
local context = {
    home = HOME,
    scripts = root .. "/scripts",
    user_scripts = root .. "/UserScripts",
    defaults = dofile(root .. "/UserConfigs/defaults.lua"),
    colors = colors,
}
hl.env("EDITOR", context.defaults.editor)
for _, name in ipairs({ "environment", "settings", "window-rules", "keybinds" }) do
    dofile(root .. "/configs/" .. name .. ".lua")(context)
end
dofile(root .. "/monitors.lua")
dofile(root .. "/UserConfigs/UserAnimations.lua")
dofile(root .. "/configs/startup.lua")(context)
