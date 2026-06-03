class_name OpponentAI
extends Node

enum OpponentDecision { CONNECT, DISCARD, APPLY_EFFECT }

signal turn_completed

@export var opponent_deck_path: String = "../OpponentDeck"
@export var opponent_hand_path: String = "../OpponentHand"
@export var opponent_timeline_path: String = "../OpponentTimeline"
@export var opponent_discard_slot_path: String = "../OpponentCardSlotDiscard"
@export var opponent_effect_slot_path: String = "../OpponentCardSlotEffect"
@export var game_manager_path: String = "../GameManager"

@onready var opponent_deck: Deck = get_node(opponent_deck_path) as Deck
@onready var opponent_hand: OpponentHand = get_node(opponent_hand_path) as OpponentHand
@onready var opponent_timeline: OpponentTimeline = get_node(opponent_timeline_path) as OpponentTimeline
@onready var opponent_discard_slot: CardSlotScn = get_node(opponent_discard_slot_path) as CardSlotScn
@onready var opponent_effect_slot: CardSlotScn = get_node(opponent_effect_slot_path) as CardSlotScn
@onready var game_manager: GameManager = get_node(game_manager_path) as GameManager
var card_effect_processor: CardEffectProcessor = CardEffectProcessor.new()
var decision_engine: OpponentDecisionEngine = OpponentDecisionEngine.new()
var _deck_data: Dictionary = {}
var _current_card: CardScn = null

@export var feedback_popup_scene: PackedScene
@export var min_score_gain_to_connect: float = 0.0

func _ready() -> void:
	_deck_data = opponent_deck.get_deck_data()

func play_turn() -> void:
	_draw_card_to_hand()
	if opponent_hand.is_empty():
		push_warning("OpponentAI: mao e deck vazios, nao e possivel jogar")
		turn_completed.emit()
		return
	
	# Pequeno delay para simular "pensamento" da IA
	await get_tree().create_timer(0.5).timeout
	
	var selected: Dictionary = _choose_card_from_hand()
	var card: CardScn = selected.get("card", null) as CardScn
	var plan: Dictionary = selected.get("plan", {}) as Dictionary
	if card == null:
		_discard_lowest_value_card_from_hand()
		await get_tree().create_timer(0.3).timeout
		turn_completed.emit()
		return

	_current_card = card
	opponent_hand.remove_card(card)
	
	Globals.debug_log("AI Decision: %s" % plan)
	_execute_decision(card, plan)
	
	# 4. Pequeno delay antes de completar o turno
	await get_tree().create_timer(0.3).timeout
	
	# 5. Emitir sinal turn_completed
	turn_completed.emit()

func _draw_card_silent() -> CardScn:
	# Acessa diretamente o array de cards do deck (é público)
	return opponent_deck.draw_card()


func _draw_card_to_hand() -> void:
	if not opponent_hand.can_receive_drawn_card():
		return
	var card: CardScn = opponent_deck.draw_card(false, false)
	if card == null:
		return
	opponent_hand.add_card(card)


func _choose_card_from_hand() -> Dictionary:
	var best_card: CardScn = null
	var best_plan: Dictionary = {}
	var best_rank: float = -INF

	for card: CardScn in opponent_hand.get_cards():
		var plan: Dictionary = _make_decision(card)
		var rank: float = _rank_plan(card, plan)
		if rank > best_rank:
			best_rank = rank
			best_card = card
			best_plan = plan

	return {
		"card": best_card,
		"plan": best_plan,
		"rank": best_rank,
	}


func _rank_plan(card: CardScn, plan: Dictionary) -> float:
	var decision: String = str(plan.get("decision", OpponentDecisionEngine.DECISION_DISCARD))
	match decision:
		OpponentDecisionEngine.DECISION_APPLY_EFFECT:
			return 1000.0
		OpponentDecisionEngine.DECISION_CONNECT:
			return 500.0 + float(plan.get("score_delta", 0.0))
		_:
			if card != null and card.data != null:
				return float(card.data.truth_value)
	return 0.0


func _discard_lowest_value_card_from_hand() -> void:
	var selected_card: CardScn = null
	var selected_value: float = INF
	for card: CardScn in opponent_hand.get_cards():
		var value: float = 0.0
		if card != null and card.data != null:
			value = float(card.data.truth_value)
		if value < selected_value:
			selected_value = value
			selected_card = card
	if selected_card == null:
		return
	opponent_hand.remove_card(selected_card)
	_discard_card(selected_card)

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
		min_score_gain_to_connect,
		opponent_timeline.get_capacity()
	)

	if card.is_special() and not _is_special_effect_useful(card):
		plan["decision"] = OpponentDecisionEngine.DECISION_DISCARD
		plan["reason"] = "special_without_useful_target"

	return plan

func _execute_decision(card: CardScn, plan: Dictionary) -> void:
	var decision: String = str(plan.get("decision", OpponentDecisionEngine.DECISION_DISCARD))
	match decision:
		OpponentDecisionEngine.DECISION_CONNECT:
			_connect_card(
				card,
				int(plan.get("insert_index", -1)),
				int(plan.get("replace_index", -1))
			)
		OpponentDecisionEngine.DECISION_DISCARD:
			_discard_card(card)
		OpponentDecisionEngine.DECISION_APPLY_EFFECT:
			_apply_effect_card(card)

func _connect_card(card: CardScn, insert_index: int = -1, replace_index: int = -1) -> void:
	# Adiciona à timeline sem animação de centro
	# A carta será virada automaticamente pela OpponentTimeline ao adicionar
	card.scale = opponent_timeline.card_scale
	card.z_index = 1
	if replace_index >= 0:
		var replaced_card: CardScn = opponent_timeline.replace_card_at(replace_index, card)
		if replaced_card != null:
			_discard_card(replaced_card)
	elif not opponent_timeline.is_full():
		# Mantem o preenchimento visual padronizado: linha superior primeiro,
		# depois linha inferior, assim como o board do jogador.
		opponent_timeline.add_card_to_hand(card)
	elif insert_index >= 0 and opponent_timeline.has_method("insert_card_at"):
		opponent_timeline.insert_card_at(card, insert_index)
	else:
		opponent_timeline.add_card_to_hand(card)
	# Nota: OpponentTimeline já chama flip_to_back() internamente

func _is_special_effect_useful(card: CardScn) -> bool:
	match card.effect:
		CardResource.SpecialEffect.FLAT_SCORE_BONUS:
			return card.data.bonus_score > 0.0
		CardResource.SpecialEffect.OPPONENT_DISCARD_RANDOM:
			return game_manager.has_useful_target_for_opponent_effect(card.effect)
		_:
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
	var effect_applied: bool = game_manager.apply_opponent_effect_to_player(card, card_effect_processor)
	if not effect_applied:
		_discard_card(card)
		return
	
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
