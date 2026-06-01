class_name DeckButton
extends Button

signal deck_pressed(deck: Dictionary)

var deck: Dictionary = {}  # dados do deck (area, theme, path, etc.)

@onready var text_label: Label = $ContentContainer/TextLabel
@onready var icon_rect: TextureRect = $ContentContainer/Icon


func _ready() -> void:
	_apply_theme()
	# Quando o botão for clicado, repassamos o deck via sinal
	pressed.connect(_on_pressed)


func setup(deck_data: Dictionary, icon_tex: Texture2D = null) -> void:
	deck = deck_data

	var area: String = str(deck_data.get("area", "Área"))
	var theme_text: String = str(deck_data.get("theme", "Tema"))

	# Busca os nós diretamente (pode ser chamado antes de _ready)
	# Usa as variáveis @onready se disponíveis, senão busca diretamente
	if not text_label:
		text_label = get_node_or_null("ContentContainer/TextLabel")
	if not icon_rect:
		icon_rect = get_node_or_null("ContentContainer/Icon")
	
	# Define o texto no Label com quebra de linha entre área e tema
	# O autowrap fará o wrap automático se o texto for muito longo
	if text_label:
		text_label.text = "%s\n%s" % [area, theme_text]

	# Se quiser sobrescrever o ícone padrão da cena
	if icon_tex != null and icon_rect:
		icon_rect.texture = icon_tex

	_apply_theme()


func _apply_theme() -> void:
	var has_texture_style: bool = ThemeManager.apply_textured_button(
		self,
		"deck_button_bg",
		"deck_button_bg_hover",
		"deck_button_bg_pressed",
		18.0
	)
	if not has_texture_style:
		ThemeManager.apply_button(self)

	if text_label:
		text_label.add_theme_color_override("font_color", ThemeManager.get_color("body", Color(0.93, 0.9, 0.8, 1.0)))
		var body_font: Font = ThemeManager.get_font("body")
		if body_font != null:
			text_label.add_theme_font_override("font", body_font)


func _on_pressed() -> void:
	deck_pressed.emit(deck)
