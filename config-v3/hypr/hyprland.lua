------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "2560x1600@165",
    position = "auto",
    scale    = "1",
})


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal           = "kitty"
local fileManager        = "kitty -e yazi"
local menu               = "quickshell:toggle-applauncher"
local notificationcenter = "quickshell:toggle-notification-center"
local clipboard          = "quickshell:toggle-clipboard"
local screenshot         = "~/.config/hypr/exec-sh/screenshot-satty.sh"
local sysInfo            = "kitty -e sudo btop"
local nvInfo             = "kitty -e sudo nvtop"

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
    hl.exec_cmd("sudo nvidia-smi -lgc 1500,3105")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("~/.config/hypr/exec-sh/start-xdph.sh")
    hl.exec_cmd("fcitx5 --replace -d")
    hl.exec_cmd("prime-run env QSG_RENDER_LOOP=threaded  quickshell")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "28")
hl.env("HYPRCURSOR_SIZE", "28")

hl.env("XMODIFIERS", "@im=fcitx")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("CLIPHIST_DB_PATH", "$XDG_RUNTIME_DIR/cliphist/db")


-----------------------
---- LOOK AND FEEL ----
-----------------------

local window_width = 0.5

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in          = 10,
        gaps_out         = 20,

        border_size      = 5,

        col              = {
            active_border   = "rgb(ffffff)",
            inactive_border = "rgb(1e1e1e)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing    = false,

        layout           = "scrolling",
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = window_width,
        follow_min_visible       = 0.2,
    },

    decoration = {
        rounding         = 20,
        rounding_power   = 4,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow           = {
            enabled = false,
        },

        blur             = {
            enabled = true,
            size    = 4,
            passes  = 2
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

-- Default springs
hl.curve("natrual", { type = "spring", mass = 1, stiffness = 360, dampening = 24 })

hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "natrual", style = "slide left" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, spring = "natrual", style = "slide right" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "natrual" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1, spring = "natrual", style = "slide bottom" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1, spring = "natrual", style = "slide top" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1, spring = "natrual", style = "slide bottom" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1, spring = "natrual", style = "slide top" })


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "us",
        kb_variant         = "",
        kb_model           = "",
        kb_options         = "",
        kb_rules           = "",

        follow_mouse       = 1,
        numlock_by_default = true,

        sensitivity        = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad           = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name          = "yjx-chip-eweadn-e7-mouse",
    sensitivity   = -0.32,
    accel_profile = "flat"
})

local state_dir = os.getenv("XDG_STATE_HOME")
    or (os.getenv("HOME") .. "/.local/state")

local state_file = state_dir .. "/touchpad/enabled"

local function read_touchpad_state()
    local file = io.open(state_file, "r")

    if not file then
        return false
    end

    local value = file:read("*l")
    file:close()

    return value == "true"
end

hl.device({
    name = "uniw0001:00-093a:0255-touchpad",
    enabled = read_touchpad_state(),
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.global(menu))
hl.bind(mainMod .. " + N", hl.dsp.global(notificationcenter))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(sysInfo))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(nvInfo))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + V", hl.dsp.global(clipboard))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))

-- Toggle touchpad
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/exec-sh/toggle-touchpad.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move windows column with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.layout("consume_or_expel next"))

-- Expand or shrink current window
hl.bind(mainMod .. " + SHIFT + E", function()
    local win = hl.get_active_window()
    local mon = hl.get_active_monitor()

    if not win or not mon then
        return
    end

    if win.size.x >= mon.width * 0.9 then
        hl.dispatch(hl.dsp.layout("colresize " .. window_width))
    else
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
    end
end)

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name           = "suppress-maximize-events",
    match          = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    -- Customize floating windows.
    name        = "customize-floating-windwos",
    match       = {
        float = true,
    },
    border_size = 0,
})

hl.window_rule({
    -- Fix fcitx5 window rounding
    name           = "fix-fcitx5-rounding",
    match          = {
        initial_title = "^Fcitx5 Input Window$"
    },
    rounding       = 0,
    rounding_power = 1,
})

hl.window_rule({
    -- Full code scrolling width
    name            = "vscode-main-window",
    match           = {
        initial_class = "^code$",
        initial_title = "^Visual Studio Code$",
        float         = false,
        modal         = false,
    },
    scrolling_width = 1.0,
})

hl.window_rule({
    -- Floating windows
    name  = "floating-windows",
    match = {
        initial_title = "^(satty|打开文件|打开文件夹|termfilechooser)$",
    },
    float = true
})

hl.layer_rule({
    match = {
        namespace = "^(quickshell-notification-center|quickshell-clipboard)$",
    },
    blur = true,
})

hl.layer_rule({
    match = {
        namespace = "^selection$",
    },
    no_anim = true
})
