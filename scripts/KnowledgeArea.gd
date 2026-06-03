class_name KnowledgeArea
extends Control

const DECKS_FILE_PATH := "res://data/decks.json"

@export var deck_button_scene: PackedScene    # arrasta DeckButton.tscn
@export var deck_icon: Texture2D              # opcional: sobrescrever ícone

@onready var background_panel: Panel = $Panel
@onready var header_icon: TextureRect = $ContentVBox/HeaderIcon
@onready var title_label: Label = $ContentVBox/TitleLabel
@onready var subtitle_label: Label = $ContentVBox/SubtitleLabel
@onready var deck_list: GridContainer = $ContentVBox/DeckScroll/DeckListWrapper/DeckList
@onready var empty_state_label: Label = $ContentVBox/EmptyStateLabel


func _ready() -> void:
	_apply_theme()
	_configure_deck_grid_alignment()
	_update_grid_columns()
	_load_decks_from_file()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_grid_columns()


func _apply_theme() -> void:
	ThemeManager.apply_background_panel(background_panel, ThemeManager.TEXTURE_MENU_BACKGROUND)

	var book_texture: Texture2D = ThemeManager.get_texture(ThemeManager.TEXTURE_MENU_BOOK)
	if book_texture != null:
		header_icon.texture = book_texture

	var area_texture: Texture2D = ThemeManager.get_texture(ThemeManager.TEXTURE_AREA_ICON)
	if area_texture != null:
		deck_icon = area_texture

	var title_font: Font = ThemeManager.get_font(ThemeManager.FONT_TITLE)
	var body_font: Font = ThemeManager.get_font(ThemeManager.FONT_BODY)
	title_label.add_theme_color_override("font_color", ThemeManager.get_color(ThemeManager.COLOR_TITLE, Color(0.96, 0.91, 0.71, 1.0)))
	subtitle_label.add_theme_color_override("font_color", ThemeManager.get_color(ThemeManager.COLOR_BODY, Color(0.93, 0.9, 0.8, 1.0)))
	empty_state_label.add_theme_color_override("font_color", ThemeManager.get_color(ThemeManager.COLOR_BODY, Color(0.93, 0.9, 0.8, 1.0)))
	if title_font != null:
		title_label.add_theme_font_override("font", title_font)
	if body_font != null:
		subtitle_label.add_theme_font_override("font", body_font)
		empty_state_label.add_theme_font_override("font", body_font)


func _load_decks_from_file() -> void:
	_clear_deck_list()
	_set_empty_state("")
	_configure_deck_grid_alignment()

	var file: FileAccess = FileAccess.open(DECKS_FILE_PATH, FileAccess.READ)
	if file == null:
		_show_load_error("Não foi possível carregar os temas.")
		push_error("Nao foi possivel abrir o arquivo de decks: %s" % DECKS_FILE_PATH)
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)

	if typeof(parsed) != TYPE_ARRAY:
		_show_load_error("Formato inválido da lista de temas.")
		push_error("Formato invalido de decks (esperado Array) em: %s" % DECKS_FILE_PATH)
		return
	if deck_button_scene == null:
		_show_load_error("Cena de botão de tema não configurada.")
		push_error("KnowledgeArea: deck_button_scene nao configurado.")
		return

	var decks_added: int = 0
	var decks: Array = parsed as Array
	for deck_value: Variant in decks:
		if typeof(deck_value) != TYPE_DICTIONARY:
			continue
		var deck: Dictionary = deck_value as Dictionary

		var path: String = str(deck.get("path", ""))
		if path == "":
			continue

		# Instancia o DeckButton.tscn
		var btn: DeckButton = deck_button_scene.instantiate() as DeckButton
		if btn == null:
			push_error("KnowledgeArea: deck_button_scene nao instancia DeckButton.")
			continue
		
		# Adiciona à árvore primeiro para que @onready seja inicializado
		deck_list.add_child(btn)
		
		# Conecta o sinal de deck selecionado
		btn.deck_pressed.connect(_on_deck_selected)
		
		# Configura o botão após estar na árvore
		btn.setup(deck, _resolve_deck_icon(deck))  # usa area/theme para texto
		decks_added += 1

	if decks_added == 0:
		_set_empty_state("Nenhum tema disponível.")
	else:
		_configure_deck_grid_alignment()


func _configure_deck_grid_alignment() -> void:
	if deck_list == null:
		return

	deck_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _resolve_deck_icon(deck: Dictionary) -> Texture2D:
	var icon_path: String = str(deck.get("icon", ""))
	if not icon_path.is_empty():
		var resource: Resource = load(icon_path)
		if resource is Texture2D:
			return resource
		push_warning("KnowledgeArea: icone invalido para deck: %s" % icon_path)

	return deck_icon


func _on_deck_selected(deck: Dictionary) -> void:
	UISoundManager.play_button_click()

	var path: String = str(deck.get("path", ""))
	if path == "":
		push_error("Deck selecionado sem 'path'. Verifique o decks.json.")
		return

	# GameSession.selected_deck_selmeta = deck
	GameSession.selected_deck = deck

	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _update_grid_columns() -> void:
	if deck_list == null:
		return

	var width: float = get_viewport_rect().size.x
	if width < 720.0:
		deck_list.columns = 1
	elif width < 1120.0:
		deck_list.columns = 2
	elif width < 1520.0:
		deck_list.columns = 3
	else:
		deck_list.columns = 4


func _clear_deck_list() -> void:
	for child: Node in deck_list.get_children():
		child.queue_free()


func _show_load_error(message: String) -> void:
	_set_empty_state(message)


func _set_empty_state(message: String) -> void:
	if empty_state_label == null:
		return

	empty_state_label.visible = not message.is_empty()
	empty_state_label.text = message
