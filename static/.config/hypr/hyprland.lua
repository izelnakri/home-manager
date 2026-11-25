-- Hyprland 0.57.2
-- Migrated from the existing hyprland.conf.

-- Monitor configuration
hl.monitor({
	output = "eDP-1",
	mode = "highres",
	position = "auto",
	scale = 2,
})

-- Existing configuration settings
hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 0,
	},

	debug = {
		disable_logs = false,
		vfr = true,
	},

	decoration = {
		blur = {
			enabled = false,
		},
		inactive_opacity = 0.80,
	},

	input = {
		repeat_delay = 200,
		sensitivity = 1.0,
		natural_scroll = true,

		touchpad = {
			natural_scroll = true,
		},
	},

	misc = {
		disable_hyprland_logo = true,
	},

	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},

	xwayland = {
		force_zero_scaling = true,
	},
})

-- Environment variables
hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

local mainMod = "SUPER"

-- Applications
hl.bind("SUPER + Q", hl.dsp.exec_cmd("alacritty"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))
hl.bind("SUPER + R", hl.dsp.exec_cmd("wofi --show drun"))

-- Window management
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

-- Exit Hyprland
hl.bind("SUPER + M", hl.dsp.exit())

-- Focus movement
hl.bind("SUPER + LEFT", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + UP", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + DOWN", hl.dsp.focus({ direction = "d" }))

-- Workspace navigation
hl.bind("SUPER + H", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + L", hl.dsp.focus({ workspace = "e+1" }))

-- Workspace switching and window movement
for i = 1, 10 do
	local key = tostring(i % 10)

	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))

	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window movement and resizing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag())
hl.bind("SUPER + mouse:273", hl.dsp.window.resize())

-- Hardware keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("volumectl -u up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("volumectl -u down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("volumectl toggle-mute"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("volumectl -m toggle-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("lightctl up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("lightctl down"))

-- Startup
hl.on("hyprland.start", function()
	hl.exec_cmd("sd activation systemd-reset-services && timedatectl set-ntp true")

	hl.exec_cmd("bash ~/.config/hypr/start.sh")

	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)
