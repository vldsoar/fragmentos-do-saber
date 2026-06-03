extends Node

const THEME_CONFIG_PATH := "res://data/theme_config.json"
const DEFAULT_THEME := "default"

const SECTION_TEXTURES := "textures"
const SECTION_FONTS := "fonts"
const SECTION_COLORS := "colors"
const SECTION_VALUES := "values"

const BUTTON_STATE_NORMAL := "normal"
const BUTTON_STATE_HOVER := "hover"
const BUTTON_STATE_PRESSED := "pressed"

const TEXTURE_MENU_BACKGROUND := "menu_background"
const TEXTURE_BOARD_BACKGROUND := "board_background"
const TEXTURE_GAME_OVER_BACKGROUND := "game_over_background"
const TEXTURE_CARD_FRONT := "card_front"
const TEXTURE_CARD_BACK := "card_back"
const TEXTURE_CARD_BACK_HOVER := "card_back_hover"
const TEXTURE_CARD_SLOT := "card_slot"
const TEXTURE_MENU_BOOK := "menu_book"
const TEXTURE_AREA_ICON := "area_icon"
const TEXTURE_DECK_BUTTON := "deck_button_bg"
const TEXTURE_DECK_BUTTON_HOVER := "deck_button_bg_hover"
const TEXTURE_DECK_BUTTON_PRESSED := "deck_button_bg_pressed"

const FONT_TITLE := "title"
const FONT_BODY := "body"
const FONT_BODY_BOLD := "body_bold"
const FONT_CARD_BOLD := "card_bold"

const COLOR_TITLE := "title"
const COLOR_BODY := "body"
const COLOR_BUTTON_BG := "button_bg"
const COLOR_BUTTON_BG_HOVER := "button_bg_hover"
const COLOR_BUTTON_BG_PRESSED := "button_bg_pressed"
const COLOR_BUTTON_TEXT := "button_text"
const COLOR_PANEL_BG := "panel_bg"
const COLOR_PANEL_BORDER := "panel_border"
const COLOR_OVERLAY := "overlay"
const COLOR_SCORE_PRIMARY := "score_primary"
const COLOR_SCORE_SECONDARY := "score_secondary"
const COLOR_SCORE_OPPONENT := "score_opponent"
const COLOR_TEACHER_HEADER := "teacher_header"
const COLOR_CARD_TITLE := "card_title"
const COLOR_CARD_BODY := "card_body"
const COLOR_CARD_CATEGORY := "card_category"
const COLOR_CARD_SHADER_BORDER := "card_shader_border_color"
const COLOR_CARD_SHADER_BACKGROUND := "card_shader_background_color"
const COLOR_DECK_COUNT := "deck_count"

const VALUE_CARD_SHADER_BORDER_WIDTH := "card_shader_border_width"
const VALUE_BUTTON_FONT_SIZE := "button_font_size"
const VALUE_MENU_BUTTON_FONT_SIZE := "menu_button_font_size"
const VALUE_GAME_OVER_BODY_FONT_SIZE := "game_over_body_font_size"
const VALUE_GAME_OVER_FEEDBACK_FONT_SIZE := "game_over_feedback_font_size"

var active_theme: String = DEFAULT_THEME
var _themes: Dictionary = {}


func _ready() -> void:
	load_theme_config()


func load_theme_config() -> void:
	var file: FileAccess = FileAccess.open(THEME_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("ThemeManager: nao foi possivel abrir %s. Usando tema interno." % THEME_CONFIG_PATH)
		_load_builtin_fallback()
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("ThemeManager: JSON invalido em %s. Usando tema interno." % THEME_CONFIG_PATH)
		_load_builtin_fallback()
		return

	var config: Dictionary = parsed
	var themes_value: Variant = config.get("themes", {})
	if not (themes_value is Dictionary):
		push_warning("ThemeManager: chave 'themes' invalida. Usando tema interno.")
		_load_builtin_fallback()
		return

	var themes_dict: Dictionary = themes_value
	_themes = themes_dict
	active_theme = str(config.get("active_theme", DEFAULT_THEME))
	if not _themes.has(active_theme):
		push_warning("ThemeManager: tema '%s' nao encontrado. Usando '%s'." % [active_theme, DEFAULT_THEME])
		active_theme = DEFAULT_THEME

	if not _themes.has(DEFAULT_THEME):
		push_warning("ThemeManager: tema default ausente. Usando fallback interno.")
		_load_builtin_fallback()


func get_value(key: String, fallback: Variant = null) -> Variant:
	return get_section_value(SECTION_VALUES, key, fallback)


func get_section_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var active_value: Variant = _get_section_value(active_theme, section, key)
	if active_value != null:
		return active_value

	var default_value: Variant = _get_section_value(DEFAULT_THEME, section, key)
	if default_value != null:
		return default_value

	return fallback


func get_texture(key: String) -> Texture2D:
	var path_value: Variant = get_section_value(SECTION_TEXTURES, key, "")
	var path: String = str(path_value)
	if path.is_empty():
		return null

	var resource: Resource = load(path)
	if resource is Texture2D:
		return resource

	push_warning("ThemeManager: textura invalida para '%s': %s" % [key, path])
	return null


func get_font(key: String) -> Font:
	var path_value: Variant = get_section_value(SECTION_FONTS, key, "")
	var path: String = str(path_value)
	if path.is_empty():
		return null

	var resource: Resource = load(path)
	if resource is Font:
		return resource

	push_warning("ThemeManager: fonte invalida para '%s': %s" % [key, path])
	return null


func get_color(key: String, fallback: Color = Color.WHITE) -> Color:
	var value: Variant = get_section_value(SECTION_COLORS, key, "")
	if value is Color:
		return value

	var text: String = str(value).strip_edges()
	if text.is_empty():
		return fallback

	if text.begins_with("#"):
		text = text.substr(1)

	if text.length() == 6 or text.length() == 8:
		return Color.html(text)

	push_warning("ThemeManager: cor invalida para '%s': %s" % [key, str(value)])
	return fallback


func make_panel_style(
	bg_key: String = COLOR_PANEL_BG,
	border_key: String = COLOR_PANEL_BORDER,
	radius: int = 6,
	border_width: int = 1,
	margin: int = 0
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = get_color(bg_key, Color(0, 0, 0, 0.8))
	style.border_color = get_color(border_key, Color(1, 1, 1, 0.35))
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


func make_button_style(state: String = BUTTON_STATE_NORMAL) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var bg_key: String = COLOR_BUTTON_BG
	if state == BUTTON_STATE_HOVER:
		bg_key = COLOR_BUTTON_BG_HOVER
	elif state == BUTTON_STATE_PRESSED:
		bg_key = COLOR_BUTTON_BG_PRESSED

	style.bg_color = get_color(bg_key, Color(0.9, 0.8, 0.45, 1.0))
	style.border_color = get_color(COLOR_PANEL_BORDER, Color(0.4, 0.25, 0.05, 1.0))
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 24.0
	style.content_margin_top = 10.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 10.0
	return style


func make_texture_style(texture_key: String, margin: float = 18.0) -> StyleBoxTexture:
	var texture: Texture2D = get_texture(texture_key)
	if texture == null:
		return null

	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


func apply_textured_button(
	button: Button,
	normal_key: String,
	hover_key: String = "",
	pressed_key: String = "",
	margin: float = 18.0
) -> bool:
	if button == null:
		return false

	var normal_style: StyleBoxTexture = make_texture_style(normal_key, margin)
	if normal_style == null:
		return false

	var hover_style: StyleBoxTexture = normal_style
	if not hover_key.is_empty():
		var configured_hover_style: StyleBoxTexture = make_texture_style(hover_key, margin)
		if configured_hover_style != null:
			hover_style = configured_hover_style

	var pressed_style: StyleBoxTexture = hover_style
	if not pressed_key.is_empty():
		var configured_pressed_style: StyleBoxTexture = make_texture_style(pressed_key, margin)
		if configured_pressed_style != null:
			pressed_style = configured_pressed_style

	var body_font: Font = get_font(FONT_BODY)
	if body_font != null:
		button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", int(get_value(VALUE_BUTTON_FONT_SIZE, 20)))
	button.add_theme_color_override("font_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_hover_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_pressed_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_focus_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_stylebox_override(BUTTON_STATE_NORMAL, normal_style)
	button.add_theme_stylebox_override(BUTTON_STATE_HOVER, hover_style)
	button.add_theme_stylebox_override(BUTTON_STATE_PRESSED, pressed_style)
	return true


func apply_background_panel(panel: Panel, texture_key: String) -> void:
	if panel == null:
		return

	var texture: Texture2D = get_texture(texture_key)
	if texture == null:
		return

	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	panel.add_theme_stylebox_override("panel", style)


func apply_button(button: Button) -> void:
	if button == null:
		return

	_apply_button_typography(button, VALUE_BUTTON_FONT_SIZE, 20)
	_apply_button_colors(button)
	button.add_theme_stylebox_override(BUTTON_STATE_NORMAL, make_button_style(BUTTON_STATE_NORMAL))
	button.add_theme_stylebox_override(BUTTON_STATE_HOVER, make_button_style(BUTTON_STATE_HOVER))
	button.add_theme_stylebox_override(BUTTON_STATE_PRESSED, make_button_style(BUTTON_STATE_PRESSED))


func apply_menu_button(button: Button) -> void:
	if button == null:
		return

	_apply_button_typography(button, VALUE_MENU_BUTTON_FONT_SIZE, 50)
	_apply_button_colors(button)
	button.add_theme_stylebox_override(BUTTON_STATE_NORMAL, make_button_style(BUTTON_STATE_NORMAL))
	button.add_theme_stylebox_override(BUTTON_STATE_HOVER, make_button_style(BUTTON_STATE_HOVER))
	button.add_theme_stylebox_override(BUTTON_STATE_PRESSED, make_button_style(BUTTON_STATE_PRESSED))


func _apply_button_typography(button: Button, font_size_key: String, fallback_size: int) -> void:
	var body_font: Font = get_font(FONT_BODY)
	if body_font != null:
		button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", int(get_value(font_size_key, fallback_size)))


func _apply_button_colors(button: Button) -> void:
	button.add_theme_color_override("font_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_hover_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_pressed_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))
	button.add_theme_color_override("font_focus_color", get_color(COLOR_BUTTON_TEXT, Color.BLACK))


func apply_label(label: Label, color_key: String = COLOR_BODY, font_key: String = FONT_BODY) -> void:
	if label == null:
		return

	var font: Font = get_font(font_key)
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", get_color(color_key, Color.WHITE))


func _get_section_value(theme_name: String, section: String, key: String) -> Variant:
	if not _themes.has(theme_name):
		return null

	var theme_value: Variant = _themes[theme_name]
	if not (theme_value is Dictionary):
		return null

	var theme: Dictionary = theme_value
	var section_value: Variant = theme.get(section, null)
	if not (section_value is Dictionary):
		return null

	var section_dict: Dictionary = section_value
	if not section_dict.has(key):
		return null

	return section_dict[key]


func _load_builtin_fallback() -> void:
	active_theme = DEFAULT_THEME
	var textures: Dictionary = {}
	textures[TEXTURE_MENU_BACKGROUND] = "res://themes/default/images/bg_main_menu.png"
	textures[TEXTURE_BOARD_BACKGROUND] = "res://themes/default/images/bg_board.png"
	textures[TEXTURE_GAME_OVER_BACKGROUND] = "res://themes/default/images/bg_game_over.png"
	textures[TEXTURE_CARD_FRONT] = "res://themes/default/images/card_front.png"
	textures[TEXTURE_CARD_BACK] = "res://themes/default/images/card_back.png"
	textures[TEXTURE_CARD_BACK_HOVER] = "res://themes/default/images/card_back.png"
	textures[TEXTURE_CARD_SLOT] = "res://themes/default/images/card_slot.png"
	textures[TEXTURE_MENU_BOOK] = "res://themes/default/images/menu_book.png"
	textures[TEXTURE_AREA_ICON] = "res://themes/default/images/area_icon.svg"

	var fonts: Dictionary = {}
	fonts[FONT_TITLE] = "res://themes/default/fonts/CinzelDecorative-Bold.ttf"
	fonts[FONT_BODY] = "res://themes/default/fonts/EBGaramond-VariableFont_wght.ttf"

	var colors: Dictionary = {}
	colors[COLOR_TITLE] = "#F5E8B5"
	colors[COLOR_BODY] = "#EEE6CC"
	colors[COLOR_BUTTON_BG] = "#F6E8B4"
	colors[COLOR_BUTTON_BG_HOVER] = "#E9CE6F"
	colors[COLOR_BUTTON_TEXT] = "#052129"
	colors[COLOR_PANEL_BG] = "#0B0D0BEA"
	colors[COLOR_PANEL_BORDER] = "#BDA35CB8"
	colors[COLOR_OVERLAY] = "#00000075"

	var default_theme: Dictionary = {}
	default_theme[SECTION_TEXTURES] = textures
	default_theme[SECTION_FONTS] = fonts
	default_theme[SECTION_COLORS] = colors

	_themes = {}
	_themes[DEFAULT_THEME] = default_theme


func texture_card_front_for_category(category: String) -> String:
	return "%s_%s" % [TEXTURE_CARD_FRONT, category.strip_edges().to_upper()]
