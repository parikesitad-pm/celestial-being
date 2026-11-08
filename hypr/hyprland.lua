-- dap_ // d-ap.my.id — macOS-flavoured, cyberpunk-neon Hyprland (Lua config, 0.57)
-- Original backed up at ~/setup-arch/hyprland.lua.orig

------------------ MONITOR ------------------
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
-- External side is set from Control Center > Displays (scripts/display.sh writes this file)
local function external_side()
  local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local file = io.open(state .. "/dap-display-side")
  if not file then return "right" end
  local side = file:read("l")
  file:close()
  return side == "left" and "left" or "right"
end
hl.monitor({ output = "",      mode = "preferred",      position = "auto-" .. external_side(), scale = 1 })

------------------ PROGRAMS ------------------
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "qs -c dap ipc call shell launcher"
local browser     = "zen-browser"
local script      = os.getenv("HOME") .. "/.config/hypr/scripts/"

------------------ ENV (GPU: Intel iGPU renders desktop, NVIDIA only on demand) ------------------
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("AQ_DRM_DEVICES", "/dev/dri/igpu:/dev/dri/dgpu")  -- symlinks created by udev rule in install.sh
hl.env("LIBVA_DRIVER_NAME", "iHD")                       -- video decode on Intel, not CPU
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

------------------ AUTOSTART ------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("env QS_ICON_THEME=candy-icons quickshell -c dap")  -- bar, launcher, calendar, control center, OSD (fallback: waybar)
  hl.exec_cmd("qs -c gn-sense -n -d")  -- power profile + keyboard RGB panel; restores the saved lighting
  -- swaync retired: the quickshell island is the notification server now
  hl.exec_cmd("hypridle")
  hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme candy-icons")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice")
end)

------------------ LOOK & FEEL ------------------
-- Celestial Being palette: GN green 2ee6a8 / Kyrios orange ff9f1c / Exia blue 3b82f6 / Virtue purple a855f7 / bg 070b14
hl.config({
  general = {
    gaps_in = 6, gaps_out = 14, border_size = 2,
    col = {
      active_border   = { colors = {"rgba(2ee6a8ff)", "rgba(ff9f1cff)", "rgba(3b82f6ff)", "rgba(a855f7ff)"}, angle = 45 },
      inactive_border = "rgba(1b2a4a66)",
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 14, rounding_power = 3,   -- squircle-ish, macOS-like corners
    active_opacity = 1.0, inactive_opacity = 0.96,
    shadow = { enabled = true, range = 40, render_power = 4, color = 0x55000000 },  -- soft mac-style drop shadow
    blur = { enabled = true, size = 10, passes = 1, vibrancy = 0.3, vibrancy_darkness = 0.2, noise = 0.015, brightness = 0.95, contrast = 1.05, popups = true },
  },

  animations = { enabled = true },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,
    vrr = 0,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms  = true,
    allow_session_lock_restore = true,  -- a crashed lock can be restarted instead of stranding the session
  },

  cursor = { inactive_timeout = 5 },
})

-- Animation curves (macOS-ish: springs = physical settle, no linear "CSS" feel)
hl.curve("mac",     { type = "bezier", points = { {0.22, 1},   {0.36, 1}   } })
hl.curve("macSoft", { type = "bezier", points = { {0.32, 0.72}, {0, 1}     } })
hl.curve("linear",  { type = "bezier", points = { {0, 0},      {1, 1}      } })
hl.curve("bounce",  { type = "spring", mass = 1, stiffness = 260, damping = 22 })
hl.curve("spaces",  { type = "spring", mass = 1, stiffness = 170, damping = 26 })  -- Spaces swipe: slight overshoot-free glide
hl.curve("pop",     { type = "spring", mass = 1, stiffness = 320, damping = 20 })  -- launcher / panels: a touch of bounce

hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "mac" })
hl.animation({ leaf = "windows",       enabled = true, speed = 5,   spring = "bounce" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   spring = "bounce", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3.5, bezier = "macSoft", style = "popin 85%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 4,   bezier = "mac" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "mac" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 40,  bezier = "linear", style = "loop" })
hl.animation({ leaf = "layers",        enabled = true, speed = 5,   spring = "pop" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 5,   spring = "pop", style = "popin 92%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3,   bezier = "macSoft", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4,   bezier = "mac" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3,   bezier = "macSoft" })
-- macOS Spaces: slide + fade so the outgoing/incoming desktop crossfades while gliding
hl.animation({ leaf = "workspaces",    enabled = true, speed = 6,   spring = "spaces", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, spring = "spaces", style = "slidefadevert 20%" })

-- Glass: blur every shell surface + per-surface animation
hl.layer_rule({ name = "glass",         match = { namespace = "^(dap-.*|waybar|swaync-.*|hyprlauncher|nwg-dock)$" }, blur = true, blur_popups = true, ignore_alpha = 0.05 })
-- dap-* surfaces animate themselves in QML (springs) — keep the compositor out of the way
hl.layer_rule({ name = "dap-self-anim", match = { namespace = "^dap-.*$" }, no_anim = true })
hl.layer_rule({ name = "dock-anim",     match = { namespace = "^nwg-dock$" },                    animation = "slide bottom" })

hl.config({
  dwindle = { preserve_split = true, precise_mouse_move = true },  -- window drag drops at the cursor side of the target
  master  = { new_status = "master" },
  input = {
    kb_layout = "us", follow_mouse = 1, sensitivity = 0,
    touchpad = { natural_scroll = true, tap_to_click = true, clickfinger_behavior = true },  -- mac trackpad
  },
})

-- Trackpad: 4 fingers, GNOME-style. ←/→ glides between workspaces, ↑ opens Overview (Mission Control), ↓ closes it
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })  -- slide the focused window, no click or modifier
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up",   action = function() hl.exec_cmd("qs -c dap ipc call shell overviewOpen") end })
hl.gesture({ fingers = 4, direction = "down", action = function() hl.exec_cmd("qs -c dap ipc call shell overviewClose") end })

------------------ KEYBINDS (SUPER = ⌘) ------------------
local m = "SUPER"

-- ⌘Space Spotlight, ⌘Return terminal, ⌘B browser, ⌘E Finder
hl.bind(m .. " + SPACE",  hl.dsp.exec_cmd(menu))
hl.bind("ALT + SPACE",    hl.dsp.exec_cmd(script .. "preview.sh"), { non_consuming = true })  -- other apps still get the key
hl.bind(m .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(m .. " + B",      hl.dsp.exec_cmd(browser))
hl.bind(m .. " + C",      hl.dsp.exec_cmd("qs -c dap ipc call shell cc"))
hl.bind("CTRL + UP",      hl.dsp.exec_cmd("qs -c dap ipc call shell overview"))  -- Control Center
hl.bind(m .. " + ALT + C",  hl.dsp.exec_cmd("qs -c dap ipc call shell calendar"))
hl.bind(m .. " + E",      hl.dsp.exec_cmd(fileManager))

-- ⌘Q / ⌘W close, ⌘Tab cycle apps, ⌘H hide (to scratchpad), ⌘⌃F fullscreen
hl.bind(m .. " + Q",         hl.dsp.window.close())
hl.bind(m .. " + W",         hl.dsp.window.close())
hl.bind(m .. " + TAB",       hl.dsp.window.cycle_next())
hl.bind(m .. " + H",         hl.dsp.window.move({ workspace = "special:hidden" }))
hl.bind(m .. " + SHIFT + H", hl.dsp.workspace.toggle_special("hidden"))
hl.bind(m .. " + CTRL + F",  hl.dsp.window.fullscreen())
hl.bind(m .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(m .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(m .. " + SHIFT + J", hl.dsp.exec_cmd(script .. "window-full-side.sh"))
hl.bind(m .. " + L",         hl.dsp.exec_cmd(script .. "lock.sh"))
hl.bind(m .. " + SHIFT + Q", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Spaces: ⌃←/⌃→ switch, ⌃⇧←/→ move window to next/prev Space and follow, ⌘⌥1-9 move window to Space N
hl.bind("CTRL + right",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind("CTRL + left",          hl.dsp.focus({ workspace = "m-1" }))
hl.bind("CTRL + SHIFT + right", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("CTRL + SHIFT + left",  hl.dsp.window.move({ workspace = "m-1" }))
for i = 1, 9 do
  hl.bind(m .. " + " .. i,            hl.dsp.focus({ workspace = i }))
  hl.bind(m .. " + ALT + " .. i,      hl.dsp.window.move({ workspace = i }))
end
hl.bind(m .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(m .. " + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))

-- Send the focused window to the monitor on its left/right; focus goes with it
hl.bind(m .. " + SHIFT + left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(m .. " + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))

-- Focus with ⌘+arrows
hl.bind(m .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(m .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(m .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(m .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mouse drag/resize
hl.bind(m .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots like macOS: ⌘⇧3 screen, ⌘⇧4 selection, ⌘⇧4 then ⌘⇧W window, ⌘⇧5 toolbar, ⌘⇧6 record. Saved to ~/Pictures/Screenshots + clipboard
hl.bind(m .. " + SHIFT + 3", hl.dsp.exec_cmd(script .. "screenshot.sh full"))
hl.bind(m .. " + SHIFT + 4", hl.dsp.exec_cmd(script .. "screenshot.sh region"))
hl.bind(m .. " + SHIFT + W", hl.dsp.exec_cmd(script .. "screenshot.sh window"))
hl.bind(m .. " + SHIFT + 5", hl.dsp.exec_cmd("qs -c dap ipc call shell screenshot"))
hl.bind(m .. " + SHIFT + 6", hl.dsp.exec_cmd(script .. "screenshot.sh record"))
hl.bind("Print",             hl.dsp.exec_cmd("qs -c dap ipc call shell screenshot"))

-- Clipboard history, notification center, color picker
hl.bind(m .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy"))
hl.bind(m .. " + N",         hl.dsp.exec_cmd("quickshell ipc -c dap call shell notifs"))
hl.bind(m .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Media / brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("code:433", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/gn-sense"))  -- N (NitroSense) key: gn-sense panel
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------ RULES ------------------
-- Desktops 1-4 always exist, from boot, even when empty. More are added only from
-- "New desktop" in the Overview; they stay until removed there or until Hyprland restarts.
local BASE_DESKTOPS = 4
for i = 1, BASE_DESKTOPS do
  hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
end

local extra_rules = {} -- workspace id -> rule, reused because rules cannot be deleted

-- Called by the Overview through `hyprctl eval`.
function dap_add_desktop(id, focus)
  if id <= BASE_DESKTOPS then return end
  local rule = extra_rules[id]
  if rule then
    rule:set_enabled(true)
  else
    rule = hl.workspace_rule({ workspace = tostring(id), persistent = true })
    extra_rules[id] = rule
  end
  if focus ~= false then hl.dispatch(hl.dsp.focus({ workspace = id })) end
end

function dap_remove_desktop(id)
  local rule = extra_rules[id]
  if rule then rule:set_enabled(false) end
end

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true })
hl.window_rule({ name = "float-pavucontrol", match = { class = "pavucontrol" }, float = true })
hl.window_rule({ name = "float-polkit", match = { class = "org.kde.polkit-kde-authentication-agent-1" }, float = true })
