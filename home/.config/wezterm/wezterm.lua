local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 14.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.max_fps = 120
config.animation_fps = 120

-- Option-Taste soll Sonderzeichen erzeugen (@ = Option+L auf deutschem Layout)
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

-- Tilde (Option+N) sofort ausgeben statt als Akzent-Taste auf das nächste Zeichen zu warten.
-- use_dead_keys greift auf macOS nur, wenn der IME aus ist.
config.use_ime = false
config.use_dead_keys = false

local act = wezterm.action

config.keys = {
	-- Option+N: Tilde direkt senden (Dead-Key-Verarbeitung liefert mit use_ime=false nichts)
	{ key = "n", mods = "OPT", action = act.SendString("~") },
	-- Cmd+Links/Rechts: Zeilenanfang / Zeilenende
	{ key = "LeftArrow", mods = "CMD", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "RightArrow", mods = "CMD", action = act.SendKey({ key = "e", mods = "CTRL" }) },
	-- Cmd+Backspace: ganze Zeile löschen
	{ key = "Backspace", mods = "CMD", action = act.SendKey({ key = "u", mods = "CTRL" }) },
	-- Option+Links/Rechts: wortweise springen
	{ key = "LeftArrow", mods = "OPT", action = act.SendKey({ key = "b", mods = "ALT" }) },
	{ key = "RightArrow", mods = "OPT", action = act.SendKey({ key = "f", mods = "ALT" }) },
	-- Option+Backspace: Wort löschen
	{ key = "Backspace", mods = "OPT", action = act.SendKey({ key = "w", mods = "CTRL" }) },
}

return config
