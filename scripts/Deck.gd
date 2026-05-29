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

var cards: Array[CardResource] = []
@onready var card_reveal_panel_ref: CardRevealPanel = get_node(card_reveal_panel_path) as CardRevealPanel
@onready var _count_deck_ref: RichTextLabel = $CountDeck

func _ready() -> void:
	_load_deck_from_json()
	shuffle()
	var total_cards = cards.size()
	Globals.debug_log("Deck loaded with %d cards from %s" % [total_cards, deck_path])
	_count_deck_ref.text = str(total_cards)

func get_deck_data() -> Dictionary:
	var selected_deck: Dictionary = GameSession.selected_deck

	if selected_deck.is_empty():
		push_warning("Nenhum deck selecionado. Voltando para tela de seleção.")
		get_tree().change_scene_to_file("res://scenes/KnowledgeArea.tscn")
		return {}

	deck_path = selected_deck.get("path", "")
	assert(deck_path != "", "Path do deck selecionado não encontrado")

	return DeckRepository.load_deck_data(deck_path)
	
func _load_deck_from_json() -> void:
	var parsed: Dictionary = get_deck_data()

	cards.clear()
	cards = DeckRepository.build_card_resources(parsed)

func draw_card() -> CardScn:
	if not silent_mode and card_reveal_panel_ref.has_card():
		return
	
	var card_data = cards.pop_front()

	if cards.is_empty():
		push_warning("Deck empty.")
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
	var total_cards = cards.size()
	Globals.debug_log("Deck reloaded with %d cards from %s" % [total_cards, deck_path])
	if _count_deck_ref:
		_count_deck_ref.text = str(total_cards)
