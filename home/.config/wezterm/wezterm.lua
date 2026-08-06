local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Rosé Pine Moon, identisch zum Ghostty-Theme "Rose Pine Moon".
-- Das mitgelieferte Schema "rose-pine-moon" wird absichtlich nicht benutzt: es
-- vertauscht Grün und Blau gegenüber der offiziellen Palette (Foam statt Pine
-- auf color2) und setzt die Auswahlfarbe auf die Hintergrundfarbe, wodurch eine
-- Selektion unsichtbar wird.
local rose_pine_moon = {
	base = "#232136",
	surface = "#2a273f",
	overlay = "#393552",
	muted = "#6e6a86",
	subtle = "#908caa",
	text = "#e0def4",
	love = "#eb6f92",
	gold = "#f6c177",
	rose = "#ea9a97",
	pine = "#3e8fb0",
	foam = "#9ccfd8",
	iris = "#c4a7e7",
	highlight_med = "#44415a",
}

local p = rose_pine_moon

config.colors = {
	foreground = p.text,
	background = p.base,
	cursor_bg = p.text,
	cursor_fg = p.base,
	cursor_border = p.text,
	selection_bg = p.highlight_med,
	selection_fg = p.text,
	split = p.overlay,
	ansi = { p.overlay, p.love, p.pine, p.gold, p.foam, p.iris, p.rose, p.text },
	brights = { p.muted, p.love, p.pine, p.gold, p.foam, p.iris, p.rose, p.text },
	-- Ohne diesen Block malt WezTerm die Tab-Leiste in seinen eigenen
	-- Standardfarben. Kein mitgeliefertes Farbschema liefert tab_bar mit.
	tab_bar = {
		background = p.base,
		active_tab = { bg_color = p.overlay, fg_color = p.text },
		inactive_tab = { bg_color = p.base, fg_color = p.muted },
		inactive_tab_hover = { bg_color = p.surface, fg_color = p.text },
		new_tab = { bg_color = p.base, fg_color = p.muted },
		new_tab_hover = { bg_color = p.surface, fg_color = p.text },
		inactive_tab_edge = p.surface,
	},
}

-- Die Fancy-Tab-Leiste zeichnet ihren Rahmen nicht aus colors.tab_bar.
config.window_frame = {
	font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
	font_size = 12.0,
	active_titlebar_bg = p.base,
	inactive_titlebar_bg = p.base,
}

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
