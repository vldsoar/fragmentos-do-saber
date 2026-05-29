class_name OpponentAI
extends Node

enum OpponentDecision { CONNECT, DISCARD, APPLY_EFFECT }

signal turn_completed

@export var opponent_deck_path: String = "../OpponentDeck"
@export var opponent_timeline_path: String = "../OpponentTimeline"
@export var opponent_discard_slot_path: String = "../OpponentCardSlotDiscard"
@export var opponent_effect_slot_path: String = "../OpponentCardSlotEffect"
@export var player_timeline_path: String = "../PlayerTimeline"
@export var player_discard_slot_path: String = "../CardSlotDiscard"
@export var card_manager_path: String = "../CardManager"

@onready var opponent_deck: Deck = get_node(opponent_deck_path) as Deck
@onready var opponent_timeline: OpponentTimeline = get_node(opponent_timeline_path) as OpponentTimeline
@onready var opponent_discard_slot: CardSlotScn = get_node(opponent_discard_slot_path) as CardSlotScn
@onready var opponent_effect_slot: CardSlotScn = get_node(opponent_effect_slot_path) as CardSlotScn
@onready var player_timeline: PlayerTimeline = get_node(player_timeline_path) as PlayerTimeline
@onready var player_discard_slot: CardSlotScn = get_node(player_discard_slot_path) as CardSlotScn
@onready var card_manager: CardManager = get_node(card_manager_path) as CardManager
var card_effect_processor: CardEffectProcessor = CardEffectProcessor.new()
var decision_engine: OpponentDecisionEngine = OpponentDecisionEngine.new()
var _deck_data: Dictionary = {}
var _current_card: CardScn = null

@export var feedback_popup_scene: PackedScene
@export var min_score_gain_to_connect: float = 0.0

func _ready() -> void:
	_deck_data = opponent_deck.get_deck_data()

func play_turn() -> void:
	# 1. Comprar carta silenciosamente
	var card = _draw_card_silent()
	if not card:
		push_warning("OpponentAI: Deck vazio, nao e possivel comprar carta")
		turn_completed.emit()
		return
	
	_current_card = card
	
	# Pequeno delay para simular "pensamento" da IA
	await get_tree().create_timer(0.5).timeout
	
	# 2. Tomar decisão
	var plan = _make_decision(card)
	
	# 3. Executar decisão
	Globals.debug_log("AI Decision: %s" % plan)
	_execute_decision(card, plan)
	
	# 4. Pequeno delay antes de completar o turno
	await get_tree().create_timer(0.3).timeout
	
	# 5. Emitir sinal turn_completed
	turn_completed.emit()

func _draw_card_silent() -> CardScn:
	# Acessa diretamente o array de cards do deck (é público)
	return opponent_deck.draw_card()

func _spawn_card(card_res: CardResource, _position: Vector2) -> CardScn:
	var card_instance: CardScn = preload("res://scenes/Card.tscn").instantiate()
	card_instance.setup(card_res)
	return card_instance

func _make_decision(card: CardScn) -> Dictionary:
	if _deck_data.is_empty():
		_deck_data = opponent_deck.get_deck_data()

	var plan: Dictionary = decision_engine.choose_action(
		_deck_data,
		card,
		opponent_timeline.get_card_names(),
		card_effect_processor.get_applied_effect_ids(),
		min_score_gain_to_connect
	)

	if card.is_special() and not _is_special_effect_useful(card):
		plan["decision"] = OpponentDecisionEngine.DECISION_DISCARD
		plan["reason"] = "special_without_useful_target"

	return plan

func _execute_decision(card: CardScn, plan: Dictionary) -> void:
	var decision: String = str(plan.get("decision", OpponentDecisionEngine.DECISION_DISCARD))
	match decision:
		OpponentDecisionEngine.DECISION_CONNECT:
			_connect_card(card, int(plan.get("insert_index", -1)))
		OpponentDecisionEngine.DECISION_DISCARD:
			_discard_card(card)
		OpponentDecisionEngine.DECISION_APPLY_EFFECT:
			_apply_effect_card(card)

func _connect_card(card: CardScn, insert_index: int = -1) -> void:
	# Adiciona à timeline sem animação de centro
	# A carta será virada automaticamente pela OpponentTimeline ao adicionar
	card.scale = Vector2(1, 1)
	card.z_index = 1
	if insert_index >= 0 and opponent_timeline.has_method("insert_card_at"):
		opponent_timeline.insert_card_at(card, insert_index)
	else:
		opponent_timeline.add_card_to_hand(card)
	# Nota: OpponentTimeline já chama flip_to_back() internamente

func _is_special_effect_useful(card: CardScn) -> bool:
	match card.effect:
		CardResource.SpecialEffect.FLAT_SCORE_BONUS:
			return card.data.bonus_score > 0.0
		CardResource.SpecialEffect.OPPONENT_DISCARD_RANDOM:
			return _player_has_discard_target()
		_:
			return false

func _player_has_discard_target() -> bool:
	for candidate in player_timeline.get_cards():
		if candidate == null:
			continue
		if not (candidate is CardScn):
			continue
		var data: CardResource = candidate.data
		if data == null:
			continue
		if data.rarity == CardResource.Rarity.COMMON and data.truth_value >= 0.99:
			return true
	return false

func _discard_card(card: CardScn) -> void:
	# Move para discard slot
	# Cartas descartadas aparecem normalmente (face visível) - não precisa virar
	card.scale = Vector2(1, 1)
	card.z_index = 1
	# Se a carta estava virada, virar para frente ao descartar
	if card.is_flipped():
		card.flip_to_front()
	opponent_discard_slot.occupy_with(card, true, 0.3)

func _apply_effect_card(card: CardScn) -> void:
	# Aplica efeito e move para effect slot
	# Cartas de efeito aparecem normalmente (face visível) - não precisa virar
	var ctx = {
		"opponent_timeline": player_timeline,
		"discard_slot": player_discard_slot,
	}
	card_effect_processor.apply_effect(card, ctx)
	
	# Se a carta estava virada, virar para frente ao aplicar efeito
	if card.is_flipped():
		card.flip_to_front()
	
	# Animação de rotação (opcional)
	var tween = get_tree().create_tween()
	tween.tween_property(card, "rotation_degrees", -30, 0.1)
	tween.tween_property(card, "rotation_degrees", 30, 0.1)
	tween.tween_property(card, "rotation_degrees", 0, 0.1)
	tween.tween_property(card, "scale", Vector2(1, 1), 0.1)
	
	card.z_index = 1
	opponent_effect_slot.occupy_with(card, true, 0.3)
	
	# Mostrar feedback para o jogador sobre o efeito aplicado pelo oponente
	_show_opponent_effect_feedback(card)

func _show_opponent_effect_feedback(card: CardScn) -> void:
	"""Mostra feedback ao jogador quando o oponente aplica um efeito"""
	if feedback_popup_scene == null:
		push_warning("OpponentAI: feedback_popup_scene não configurado")
		return
	
	if not card or not card.data:
		return
	
	var popup: FeedbackEffect = feedback_popup_scene.instantiate() as FeedbackEffect
	get_tree().current_scene.add_child(popup)
	
	# Formatar mensagem indicando que foi o oponente que aplicou
	var message = "Oponente aplicou: %s" % card.data.effect_description
	
	# Usar modal para efeitos importantes, toast para efeitos simples
	if card.effect == CardResource.SpecialEffect.FLAT_SCORE_BONUS:
		# Toast para bônus de pontuação (mais rápido)
		popup.show_toast(message, 1.5)
	else:
		# Modal para efeitos que afetam o jogador (precisa confirmação)
		popup.show_modal(message, "OK")
