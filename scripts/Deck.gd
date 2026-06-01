class_name Deck
extends Node2D

signal card_drawn(card)

const DEFAULT_DECK_PATH := "res://data/deck_rf.json"
const CARD_SCN_PATH := "res://scenes/Card.tscn"

@export var deck_path: String = DEFAULT_DECK_PATH
@export var silent_mode: bool = false
@export var is_opponent: bool = false
@export var card_reveal_panel_path: String = "../HUD/CardRevealPanel"
@export var card_manager_path: String = "../CardManager"
@export var attention_pulse_scale: float = 1.02

var cards: Array[CardResource] = []
@onready var card_reveal_panel_ref: CardRevealPanel = get_node(card_reveal_panel_path) as CardRevealPanel
@onready var _count_deck_ref: RichTextLabel = $CountDeck
@onready var _deck_sprite: Sprite2D = $Sprite2D
var _normal_deck_texture: Texture2D = null
var _attention_deck_texture: Texture2D = null
var _attention_tween: Tween = null
var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_base_scale = scale
	_apply_theme()
	_load_deck_from_json()
	shuffle()
	var total_cards: int = cards.size()
	Globals.debug_log("Deck loaded with %d cards from %s" % [total_cards, deck_path])
	_count_deck_ref.text = str(total_cards)


func _apply_theme() -> void:
	_normal_deck_texture = ThemeManager.get_texture("card_back")
	_attention_deck_texture = ThemeManager.get_texture("card_back_hover")
	if _normal_deck_texture != null:
		_deck_sprite.texture = _normal_deck_texture
	CardVisualMetrics.apply_sprite_size(_deck_sprite)
	_count_deck_ref.modulate = ThemeManager.get_color("deck_count", _count_deck_ref.modulate)


func start_draw_attention() -> void:
	if silent_mode or is_opponent or cards.is_empty():
		return
	if _attention_tween != null and _attention_tween.is_running():
		return

	if _attention_deck_texture != null:
		_deck_sprite.texture = _attention_deck_texture

	scale = _base_scale
	modulate = Color.WHITE
	_attention_tween = create_tween().set_loops()
	_attention_tween.tween_property(self, "scale", _base_scale * attention_pulse_scale, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_attention_tween.parallel().tween_property(self, "modulate", Color(1.12, 1.12, 1.12, 1.0), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_attention_tween.tween_property(self, "scale", _base_scale, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_attention_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func stop_draw_attention() -> void:
	if _attention_tween != null:
		_attention_tween.kill()
		_attention_tween = null

	scale = _base_scale
	modulate = Color.WHITE
	if _normal_deck_texture != null:
		_deck_sprite.texture = _normal_deck_texture

func get_deck_data() -> Dictionary:
	var selected_deck: Dictionary = GameSession.selected_deck

	if selected_deck.is_empty():
		push_warning("Nenhum deck selecionado. Voltando para tela de seleção.")
		get_tree().change_scene_to_file("res://scenes/KnowledgeArea.tscn")
		return {}

	deck_path = str(selected_deck.get("path", ""))
	assert(deck_path != "", "Path do deck selecionado não encontrado")

	return DeckRepository.load_deck_data(deck_path)
	
func _load_deck_from_json() -> void:
	var parsed: Dictionary = get_deck_data()

	cards.clear()
	cards = DeckRepository.build_card_resources(parsed)

func draw_card() -> CardScn:
	if not silent_mode and card_reveal_panel_ref.has_card():
		return

	stop_draw_attention()
	
	var card_data = cards.pop_front()

	if cards.is_empty():
		push_warning("Deck empty.")
		stop_draw_attention()
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		_count_deck_ref.visible = false
	
	if not card_data:
		return
	
	_count_deck_ref.text = str(cards.size())
	var card_scn = _spawn_card(card_data, Vector2(0, 0))
	card_scn.flip_to_back()
	var card_manager: CardManager = get_node(card_manager_path) as CardManager
	card_manager.add_child(card_scn)
	if not is_opponent:
		card_manager.connect_card_signals(card_scn)
	card_scn.name = card_scn.data.id
	if not silent_mode:
		UISoundManager.play_take_card()

	if not silent_mode:
		emit_signal("card_drawn", card_scn)

	return card_scn
	

func _spawn_card(card_res: CardResource, _position: Vector2) -> CardScn:
	var card_instance: CardScn = preload(CARD_SCN_PATH).instantiate()
	card_instance.setup(card_res, is_opponent)

	return card_instance

func shuffle() -> void:
	cards.shuffle()

func set_deck_path(path: String) -> void:
	deck_path = path
	_load_deck_from_json()
	shuffle()
	var total_cards: int = cards.size()
	Globals.debug_log("Deck reloaded with %d cards from %s" % [total_cards, deck_path])
	if _count_deck_ref:
		_count_deck_ref.text = str(total_cards)
