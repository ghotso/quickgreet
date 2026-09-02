-- Hyprland config for hosting quickgreet under greetd.
--
--   /etc/greetd/config.toml:
--     command = "start-hyprland -- -c /etc/greetd/hyprland-greeter.lua"
--     user = "greeter"
--
-- Worth preferring if you already run Hyprland: the greeter then uses the same
-- monitor semantics as your real session, so a dual-monitor layout doesn't have
-- to be re-expressed in a second compositor's syntax and drift from the one
-- that works.
--
-- This is the Lua config format, which Hyprland 0.56 warns is replacing the old
-- .conf one ("support for which will be removed in Hyprland 0.57"). On a
-- greeter that warning is not just noise -- it is drawn over the login screen.
-- If you are on an older Hyprland, use hyprland-greeter.conf instead.

-- Outputs. Copy these from your session's own config -- `hyprctl monitors -j`
-- prints exactly what you need.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
-- Example, dual 4K side by side:
-- hl.monitor({ output = "DP-3", mode = "3840x2160@60", position = "0x0",    scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "3840x2160@60", position = "3840x0", scale = 1 })

hl.config({
    input = {
        -- Match your session's layout, or you'll be typing your password on
        -- the wrong keymap -- a genuinely confusing way to be locked out,
        -- because it looks identical to getting the password wrong.
        kb_layout          = "us",
        kb_variant         = "",
        numlock_by_default = true,
        follow_mouse       = 1,
    },

    -- No decorations, no animations to wait through, nothing to alt-tab to.
    general = {
        border_size = 0,
        gaps_in     = 0,
        gaps_out    = 0,
    },
    decoration = {
        rounding = 0,
        blur     = { enabled = false },
        shadow   = { enabled = false },
    },
    animations = { enabled = false },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "rgb(000000)",
    },
})

-- The greeter is the only client; when it exits, so does the compositor.
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p /usr/share/quickgreet/greeter.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)

-- An escape hatch: if the greeter ever fails to draw, this still gets you out.
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
