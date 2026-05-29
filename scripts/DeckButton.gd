class_name DeckButton
extends Button

signal deck_pressed(deck: Dictionary)

var deck: Dictionary = {}  # dados do deck (area, theme, path, etc.)

@onready var text_label: Label = $ContentContainer/TextLabel
@onready var icon_rect: TextureRect = $ContentContainer/Icon


func _ready() -> void:
	# Quando o botão for clicado, repassamos o deck via sinal
	pressed.connect(_on_pressed)


func setup(deck_data: Dictionary, icon_tex: Texture2D = null) -> void:
	deck = deck_data

	var area: String = deck_data.get("area", "Área")
	var theme_text: String = deck_data.get("theme", "Tema")

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


func _on_pressed() -> void:
	deck_pressed.emit(deck)
