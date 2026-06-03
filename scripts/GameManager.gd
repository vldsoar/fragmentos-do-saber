class_name GameManager
extends Node2D

# GameRoot.gd (ou GameManager.gd)
@export var card_reveal_panel_path: String = "../HUD/CardRevealPanel"
@export var player_hand_path: String = "../PlayerHand"
@export var player_timeline_path: String = "../PlayerTimeline"
@export var card_manager_path: String = "../CardManager"
@export var discard_slot_path: String = "../CardSlotDiscard"
@export var effect_slot_path: String = "../CardSlotEffect"
@export var deck_path: String = "../Deck"
@export var input_manager_path: String = "../InputManager"
@export var knowledge_clock_path: String = "../HUD/KnowledgeClock"
@export var score_hud_path: String = "../HUD/ScoreBonus"
@export var game_over_screen_path: String = "../HUD/GameOverScreen"
@export var hud_path: String = "../HUD"
@export var opponent_deck_path: String = "../OpponentDeck"
@export var opponent_timeline_path: String = "../OpponentTimeline"
@export var opponent_discard_slot_path: String = "../OpponentCardSlotDiscard"
@export var opponent_effect_slot_path: String = "../OpponentCardSlotEffect"
@export var opponent_ai_path: String = "../OpponentAI"
@export var board_background_path: String = "../Panel"

@onready var card_reveal_panel: CardRevealPanel = get_node(card_reveal_panel_path) as CardRevealPanel
@onready var player_hand: PlayerHand = get_node(player_hand_path) as PlayerHand
@onready var player_timeline: PlayerTimeline = get_node(player_timeline_path) as PlayerTimeline
@onready var card_manager: CardManager = get_node(card_manager_path) as CardManager
@onready var discard_slot: CardSlotScn = get_node(discard_slot_path) as CardSlotScn
@onready var effect_slot: CardSlotScn = get_node(effect_slot_path) as CardSlotScn

@onready var deck: Deck = get_node(deck_path) as Deck
@onready var input_manager: InputManager = get_node(input_manager_path) as InputManager
@onready var knowledge_clock: KnowledgeClock = get_node(knowledge_clock_path) as KnowledgeClock
@onready var score_hud: ScoreHUD = get_node(score_hud_path) as ScoreHUD
@onready var game_over_screen: GameOverScreen = get_node(game_over_screen_path) as GameOverScreen
@onready var hud: CanvasLayer = get_node(hud_path) as CanvasLayer

@onready var fsm: StateMachine = StateMachine.new()
@onready var _cardEffectProcessor: CardEffectProcessor
@onready var _cardActionController: CardActionController = CardActionController.new()
@onready var _turnController: TurnController = TurnController.new()
@onready var _matchResultController: MatchResultController = MatchResultController.new()

# Opponent components
@onready var opponent_deck: Deck = get_node(opponent_deck_path) as Deck
@onready var opponent_timeline: OpponentTimeline = get_node(opponent_timeline_path) as OpponentTimeline
@onready var opponent_discard_slot: CardSlotScn = get_node(opponent_discard_slot_path) as CardSlotScn
@onready var opponent_effect_slot: CardSlotScn = get_node(opponent_effect_slot_path) as CardSlotScn
@onready var opponent_ai: OpponentAI = get_node(opponent_ai_path) as OpponentAI
@onready var background_music: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"
@onready var board_background_panel: Panel = get_node(board_background_path) as Panel

@export var feedback_popup_scene: PackedScene

const CENTER_POS := Vector2(960, 440)
const TURN_BANNER_TEXT: String = "Sua vez"
const FINAL_TURN_BANNER_TEXT: String = "Ultima rodada"
const REPLACEMENT_BANNER_TEXT: String = "Escolha uma carta do board"
const REPLACE_EFFECT_HAND_BANNER_TEXT: String = "Escolha uma carta comum da mão"
const REVEAL_CARD_Z_INDEX := 1000
const REPLACEMENT_PREVIEW_POS := Vector2(1510, 520)
const REPLACEMENT_PREVIEW_SCALE := Vector2(1.15, 1.15)
const REPLACEMENT_PREVIEW_Z_INDEX := 20

enum GameState {
	WAITING_INPUT,
	MUST_DRAW,
	RESOLVE_ACTIONS,
	RESOLVING_TURN,
	END_ROUND_SCORING,
	GAME_OVER,
}

var current_state : GameState:
	get:
		return fsm.current
var current_turn: int = 1
var max_turns: int = Globals.DEFAULT_TURNS
var turn_banner: Control = null
var turn_banner_tween: Tween = null
var card_action_used_this_turn: bool = false
var pending_replacement_card: CardScn = null
var pending_replacement_effect_card: CardScn = null
var selected_hand_card: CardScn = null
		
#const _STATES_FOR

func _ready():
	_apply_theme()
	# configure states
	_configureState()

	# setup Deck
	deck.connect("card_drawn", _on_card_drawn)
	input_manager.connect("deck_clicked", _on_deck_clicked)

	# setup Card Panel
	card_reveal_panel.connect("connect_selected", _on_connect_selected)
	card_reveal_panel.connect("discard_selected", _on_discard_selected)
	card_reveal_panel.connect("apply_effect_selected", _on_apply_effect_selected)
	card_reveal_panel.connect("keep_selected", _on_keep_selected)
	
	# setup End Game
	game_over_screen.visible = false
	game_over_screen.play_again_pressed.connect(_on_play_again_pressed)
	game_over_screen.exit_pressed.connect(_on_exit_pressed)
	
	# Engines
	_cardEffectProcessor = CardEffectProcessor.new()
	_cardActionController.configure(player_timeline, discard_slot, effect_slot, player_hand)
	max_turns = _turnController.calculate_max_turns(deck.cards.size())
	Globals.debug_log("Max turns for this match: %d from %d deck cards" % [max_turns, deck.cards.size()])
	SettingsManager.apply_audio_settings()
	if background_music:
		if SettingsManager.music_enabled:
			background_music.play()
		else:
			background_music.stop()
	
	# Obter OpponentAI se existir na cena
	opponent_ai.turn_completed.connect(_on_opponent_turn_completed)
	call_deferred("_begin_player_turn")
	#_update_knowledge_clock(current_state)


func _apply_theme() -> void:
	ThemeManager.apply_background_panel(board_background_panel, ThemeManager.TEXTURE_BOARD_BACKGROUND)
	
	
func _configureState() -> void:
	fsm.configure(
		GameState.WAITING_INPUT,
		{
			GameState.WAITING_INPUT: [GameState.MUST_DRAW],
			GameState.MUST_DRAW: [GameState.RESOLVE_ACTIONS],
			GameState.RESOLVE_ACTIONS: [GameState.RESOLVING_TURN, GameState.WAITING_INPUT],
			GameState.RESOLVING_TURN: [GameState.END_ROUND_SCORING],
			GameState.END_ROUND_SCORING: [GameState.WAITING_INPUT, GameState.GAME_OVER],
			GameState.GAME_OVER: []
		}
	)
	fsm.state_changed.connect(_on_game_state_changed)
	current_state = fsm.current

func _on_game_state_changed(old_state: GameState, new_state: GameState) -> void:
	Globals.debug_log("STATE CHANGED: %s -> %s" % [GameState.find_key(old_state), GameState.find_key(new_state)])
	if new_state == GameState.WAITING_INPUT:
		await _begin_player_turn()
		return

	if new_state != GameState.WAITING_INPUT:
		deck.stop_draw_attention()

	if new_state == GameState.RESOLVING_TURN:
		# Iniciar turno do oponente
		opponent_ai.play_turn()
		return
	
	if new_state == GameState.END_ROUND_SCORING:
		knowledge_clock.flip()
		_update_knowledge_clock(new_state)

		if _turnController.is_final_turn(current_turn, max_turns):
			fsm.transition_to(GameState.GAME_OVER)
		else:
			current_turn = _turnController.advance_turn(current_turn, max_turns)
			fsm.transition_to(GameState.WAITING_INPUT)

		return

	if new_state == GameState.GAME_OVER:
		_handle_game_over()
		# só pra garantir que o relógio mostre "fim"
		_update_knowledge_clock(new_state)
		return
	#_update_knowledge_clock(new_state)
func _on_opponent_turn_completed() -> void:
	# Pequeno delay só pra animação respirar
	await get_tree().create_timer(1.0).timeout

	if fsm.current == GameState.RESOLVING_TURN:
		fsm.transition_to(GameState.END_ROUND_SCORING)

func can_drag_card(card: CardScn) -> bool:
	if card.is_revealed:
		return false
	if player_hand.has(card):
		return false
	if pending_replacement_card != null or pending_replacement_effect_card != null:
		return false
	# só pode arrastar cartas da timeline na fase de ações depois do draw
	var states_for_dragged: Array[int] = [GameState.RESOLVE_ACTIONS, GameState.WAITING_INPUT]
	if not states_for_dragged.has(current_state):
		return false

	# TODO: impedir arrastar carta revelada, carta especial em uso etc.
	return true


func try_handle_card_click(card: CardScn) -> bool:
	if card == null:
		return false

	if pending_replacement_card != null:
		if player_timeline.has(card):
			_replace_board_card(card)
			return true
		if player_hand.has(card):
			_cancel_pending_replacement_state()
			_return_selected_hand_card()
			_request_hand_card_action(card)
			return true
		return false

	if pending_replacement_effect_card != null:
		if player_hand.has(card):
			if card == pending_replacement_effect_card:
				_cancel_pending_replacement_state()
				_request_hand_card_action(card)
				return true
			if _is_valid_replace_effect_hand_card(card):
				_start_board_replacement(card)
			else:
				_show_replace_effect_hand_banner()
			return true
		return false

	if player_hand.has(card):
		_request_hand_card_action(card)
		return true

	return false


func _request_hand_card_action(card: CardScn) -> void:
	if current_state != GameState.RESOLVE_ACTIONS:
		return
	if card_action_used_this_turn:
		return

	if selected_hand_card != null and selected_hand_card != card:
		_return_selected_hand_card()

	selected_hand_card = card
	card.set_as_revealed()
	card.enable_collision()
	card.z_index = REVEAL_CARD_Z_INDEX
	card_manager.animate_to_center(card, CENTER_POS)
	card_reveal_panel.show_for(card)

func request_play_special(card: CardScn) -> bool:
	if not _can_play_special(card):
		push_warning("Can't apply special card: ", card.is_special())
		push_warning("Can't apply special current_state: ", current_state)
		return false

	if card.effect == CardResource.SpecialEffect.REPLACE_BOARD_CARD:
		return _can_start_replace_board_effect(card)

	var effect_applied: bool = _cardEffectProcessor.apply_effect(card, {
		"opponent_timeline": opponent_timeline,
		"discard_slot": opponent_discard_slot,
	})
	if not effect_applied:
		return false

	var accumulated_score: float = _cardEffectProcessor.get_accumulated_score()
	if accumulated_score > 0:
		score_hud.set_score(accumulated_score)
	
	return true
	# (por enquanto, sem estado extra)


func has_useful_target_for_opponent_effect(effect: CardResource.SpecialEffect) -> bool:
	match effect:
		CardResource.SpecialEffect.OPPONENT_DISCARD_RANDOM:
			return _player_has_true_common_card()
		_:
			return false


func apply_opponent_effect_to_player(card: CardScn, effect_processor: CardEffectProcessor) -> bool:
	if card == null or effect_processor == null:
		return false

	return effect_processor.apply_effect(card, {
		"opponent_timeline": player_timeline,
		"discard_slot": discard_slot,
	})


func _player_has_true_common_card() -> bool:
	for candidate: CardScn in player_timeline.get_cards():
		if candidate == null:
			continue
		var data: CardResource = candidate.data
		if data == null:
			continue
		if data.rarity == CardResource.Rarity.COMMON and data.truth_value >= 0.99:
			return true
	return false


func _can_start_replace_board_effect(card: CardScn) -> bool:
	if card == null or card.effect != CardResource.SpecialEffect.REPLACE_BOARD_CARD:
		return false
	if player_timeline.get_cards().is_empty():
		push_warning("REPLACE_BOARD_CARD sem alvo: board vazio.")
		return false
	for hand_card: CardScn in player_hand.get_cards():
		if _is_valid_replace_effect_hand_card(hand_card):
			return true

	push_warning("REPLACE_BOARD_CARD sem carta comum valida na mao.")
	return false


func _is_valid_replace_effect_hand_card(card: CardScn) -> bool:
	if card == null:
		return false
	if card == pending_replacement_effect_card:
		return false
	if not player_hand.has(card):
		return false
	var data: CardResource = card.data
	if data == null:
		return false
	return data.rarity == CardResource.Rarity.COMMON


func _can_play_special(card: CardScn) -> bool:
	return current_state == GameState.RESOLVE_ACTIONS and card.is_special() and not card_action_used_this_turn

func handle_card_drop(ctx: DropContext) -> void:
	var card: CardScn = ctx.card
	var target_card: CardScn = ctx.target_card
	var card_was_in_timeline: bool = ctx.card_was_in_timeline
	var timeline_target_index: int = ctx.timeline_target_index

	if current_state != GameState.RESOLVE_ACTIONS:
		card.position = card.start_position
		return

	match ctx.type:
		DropContext.DropType.ON_EMPTY_SLOT:
			Globals.debug_log("GM: drop em slot vazio")
			if card_was_in_timeline:
				player_timeline.remove_card(card)
			ctx.slot.occupy_with(card)
			return
			#card.position = card.start_position
			#return

		DropContext.DropType.ON_TIMELINE_CARD:
			Globals.debug_log("GM: drop em outra carta da timeline")
			var target_index: int = player_timeline.find_index_of(target_card)

			if card_was_in_timeline:
				# Reordena dentro da timeline
				player_timeline.card_being_dragged = card
				player_timeline.reorder_card(card, target_index)
			else:
				# Nova carta indo pra timeline
				player_timeline.card_being_dragged = card
				player_timeline.add_card_to_hand(card)
			return

		DropContext.DropType.ON_TIMELINE_AREA:
			Globals.debug_log("GM: drop na area da timeline, indice: %s" % timeline_target_index)
			if card_was_in_timeline:
				player_timeline.card_being_dragged = card
				player_timeline.reorder_card(card, timeline_target_index)
			else:
				player_timeline.card_being_dragged = card
				player_timeline.add_card_to_hand(card)
			return

		DropContext.DropType.INVALID:
			Globals.debug_log("GM: drop invalido, voltando pra posicao inicial")
			# Volta pra posição original
			card.position = card.start_position
			return
	


func _on_card_drawn(card: CardScn) -> void:
	if current_state != GameState.MUST_DRAW:
		return
	player_hand.add_card(card)
	fsm.transition_to(GameState.RESOLVE_ACTIONS)

# Listen buttons panels
func _on_connect_selected(card: CardScn) -> void:
	if not _can_use_hand_card(card):
		return
	if player_timeline.is_full():
		_start_board_replacement(card)
		return

	_cardActionController.connect_card_to_timeline(card)
	selected_hand_card = null
	card_action_used_this_turn = true
	card_reveal_panel.clear_current_card()

func _on_discard_selected(card: CardScn) -> void:
	if not _can_use_hand_card(card):
		return

	_cardActionController.discard_card(card)
	selected_hand_card = null
	card_action_used_this_turn = true

func _on_apply_effect_selected(card: CardScn) -> void:
	if not _can_use_hand_card(card):
		return

	Globals.debug_log("apply_effect_selected...")
	if not request_play_special(card):
		card_reveal_panel.clear_current_card()
		_return_selected_hand_card()
		return

	if card.effect == CardResource.SpecialEffect.REPLACE_BOARD_CARD:
		_start_replace_board_effect(card)
		return
	
	Globals.debug_log("requested play applied")
	_cardActionController.move_effect_card(card)
	selected_hand_card = null
	card_reveal_panel.clear_current_card()
	
	_show_feedback(card, func():
		card_action_used_this_turn = true
	) # ou o valor real do efeito


func _on_keep_selected(_card: CardScn) -> void:
	_cancel_pending_replacement_state()
	_return_selected_hand_card()


func _on_deck_clicked() -> void:
	if current_state != GameState.WAITING_INPUT:
		# Ignora clique no deck fora da fase certa
		return

	deck.stop_draw_attention()
	if not player_hand.can_receive_drawn_card():
		push_warning("Mao cheia; jogue, descarte ou aplique uma carta antes de comprar.")
		fsm.transition_to(GameState.RESOLVE_ACTIONS)
		return

	# Transiciona pra fase de carta comprada
	#current_state = GameState.MUST_DRAW
	fsm.transition_to(GameState.MUST_DRAW)
	deck.draw_card()

func _on_audio_stream_player_2d_finished() -> void:
	#$"../AudioStreamPlayer2D".stop()
	pass


func _on_button_end_turn_requested() -> void:
	if current_state != GameState.RESOLVE_ACTIONS:
		return
	if not can_end_player_turn():
		return
	_cancel_pending_replacement_state()
	_return_selected_hand_card()
#	Opponent
	fsm.transition_to(GameState.RESOLVING_TURN)
	#await get_tree().create_timer(2.0).timeout
	#fsm.transition_to(GameState.END_ROUND_SCORING)

func _update_knowledge_clock(state: int) -> void:
	if not knowledge_clock:
		return
	knowledge_clock.set_turn(current_turn)
	knowledge_clock.set_progress(_calculate_state_progress(state))

func _calculate_state_progress(state: int) -> float:
	var ordered_states: Array[int] = [
		GameState.WAITING_INPUT,
		GameState.MUST_DRAW,
		GameState.RESOLVE_ACTIONS,
		GameState.RESOLVING_TURN,
		GameState.END_ROUND_SCORING,
		GameState.GAME_OVER
	]

	var idx: int = ordered_states.find(state)
	if idx == -1:
		return 0.0
	return float(idx) / float(ordered_states.size() - 1)

func _handle_game_over() -> void:
	var deck_data: Dictionary = deck.get_deck_data()
	var player_timeline_ids: Array = player_timeline.get_card_names()
	var opponent_timeline_ids: Array = opponent_timeline.get_card_names()
	var player_effect_ids: Array = _cardEffectProcessor.get_applied_effect_ids()
	var opponent_effect_ids: Array = opponent_ai.card_effect_processor.get_applied_effect_ids()
	var match_result: Dictionary = _matchResultController.build_match_result(
		deck_data,
		player_timeline_ids,
		opponent_timeline_ids,
		player_effect_ids,
		opponent_effect_ids
	)
	var result: ResultGame = match_result["player_result"] as ResultGame
	var result_opponent: ResultGame = match_result["opponent_result"] as ResultGame
	var teacher_context: Dictionary = {}
	var teacher_context_value: Variant = match_result.get("teacher_context", {})
	if teacher_context_value is Dictionary:
		teacher_context = teacher_context_value
	var did_win: bool = bool(match_result["did_win"])
	var result_winner: ResultGame = ResultGame.get_greater(result, result_opponent)

	Globals.debug_log("Game over! Result winner: %s" % result_winner.total_score)
	game_over_screen.show_result(result, did_win, result_opponent, teacher_context)


func _can_use_hand_card(card: CardScn) -> bool:
	return current_state == GameState.RESOLVE_ACTIONS \
		and not card_action_used_this_turn \
		and card != null \
		and player_hand.has(card)


func can_end_player_turn() -> bool:
	return current_state == GameState.RESOLVE_ACTIONS \
		and pending_replacement_card == null \
		and pending_replacement_effect_card == null \
		and not is_card_reveal_active() \
		and not player_hand.is_over_limit()


func is_card_reveal_active() -> bool:
	return card_reveal_panel != null and card_reveal_panel.has_card()


func _replace_board_card(target_card: CardScn) -> void:
	if pending_replacement_card == null:
		return
	if not player_timeline.has(target_card):
		return

	if pending_replacement_effect_card != null:
		_confirm_replace_board_effect(target_card)
		return

	var replacement_card: CardScn = pending_replacement_card
	var target_index: int = player_timeline.find_index_of(target_card)
	if target_index < 0:
		return

	player_timeline.set_replacement_targets_highlighted(false)
	player_hand.remove_card(replacement_card)
	replacement_card.disable_as_revealed()
	replacement_card.z_index = 1
	var replaced_card: CardScn = player_timeline.replace_card_at(target_index, replacement_card)
	if replaced_card != null:
		discard_slot.occupy_with(replaced_card, true, 0.3)

	selected_hand_card = null
	pending_replacement_card = null
	card_action_used_this_turn = true
	card_reveal_panel.clear_current_card()


func _start_board_replacement(card: CardScn) -> void:
	pending_replacement_card = card
	selected_hand_card = card
	card.set_as_revealed()
	card.z_index = REPLACEMENT_PREVIEW_Z_INDEX
	card_manager.reset_hover_state()
	card_manager.animate_to_replacement_preview(card, REPLACEMENT_PREVIEW_POS, REPLACEMENT_PREVIEW_SCALE)
	player_timeline.set_replacement_targets_highlighted(true)
	card_reveal_panel.show_replacement_mode(card)
	call_deferred("_show_replacement_banner")


func _cancel_board_replacement() -> void:
	if pending_replacement_card == null:
		return

	pending_replacement_card = null
	card_manager.reset_hover_state()
	player_timeline.set_replacement_targets_highlighted(false)


func is_board_replacement_active() -> bool:
	return pending_replacement_card != null


func _show_replacement_banner() -> void:
	if pending_replacement_card == null:
		return
	await _show_turn_banner(REPLACEMENT_BANNER_TEXT)


func _start_replace_board_effect(card: CardScn) -> void:
	pending_replacement_effect_card = card
	card_reveal_panel.clear_current_card()
	_return_selected_hand_card()
	_show_replace_effect_hand_banner()


func _confirm_replace_board_effect(target_card: CardScn) -> void:
	if pending_replacement_effect_card == null:
		return

	var effect_card: CardScn = pending_replacement_effect_card
	var replacement_card: CardScn = pending_replacement_card
	var effect_applied: bool = _cardEffectProcessor.apply_effect(effect_card, {
		"player_timeline": player_timeline,
		"player_hand": player_hand,
		"replacement_card": replacement_card,
		"target_card": target_card,
		"discard_slot": discard_slot,
	})
	if not effect_applied:
		push_warning("REPLACE_BOARD_CARD nao foi aplicado.")
		_cancel_pending_replacement_state()
		card_reveal_panel.clear_current_card()
		_return_selected_hand_card()
		return

	_cardActionController.move_effect_card(effect_card)
	selected_hand_card = null
	pending_replacement_card = null
	pending_replacement_effect_card = null
	card_action_used_this_turn = true
	player_timeline.set_replacement_targets_highlighted(false)
	card_reveal_panel.clear_current_card()
	_show_feedback(effect_card, func(): pass)


func _cancel_pending_replacement_state() -> void:
	_cancel_board_replacement()
	pending_replacement_effect_card = null


func _show_replace_effect_hand_banner() -> void:
	if pending_replacement_effect_card == null:
		return
	call_deferred("_show_replace_effect_hand_banner_deferred")


func _show_replace_effect_hand_banner_deferred() -> void:
	if pending_replacement_effect_card == null:
		return
	await _show_turn_banner(REPLACE_EFFECT_HAND_BANNER_TEXT)


func _return_selected_hand_card() -> void:
	if selected_hand_card == null:
		return
	if player_hand.has(selected_hand_card):
		selected_hand_card.disable_as_revealed()
		selected_hand_card.z_index = 1
		selected_hand_card.scale = Vector2.ONE
		selected_hand_card.set_meta("base_scale", Vector2.ONE)
		player_hand.update_positions()
	selected_hand_card = null

func _show_feedback(card: CardScn, callable: Callable) -> void:
	if feedback_popup_scene == null:
		push_warning("feedback_popup_scene não configurado")
		return

	var popup: FeedbackEffect = feedback_popup_scene.instantiate() as FeedbackEffect
	get_tree().current_scene.add_child(popup)

	var on_finished: Callable = func():
		Globals.debug_log("Feedback finalizado")
		callable.call()

	if card.effect == CardResource.SpecialEffect.FLAT_SCORE_BONUS:
		# Toast: termina, depois chama callable
		popup.show_toast(card.data.effect_description, 1.0, on_finished)
	else:
		# Modal: OK chama callable
		popup.show_modal(card.data.effect_description, "OK", on_finished)


func _begin_player_turn() -> void:
	if current_state != GameState.WAITING_INPUT:
		return

	card_action_used_this_turn = false
	_cancel_pending_replacement_state()
	_return_selected_hand_card()
	_update_knowledge_clock(current_state)
	await _show_player_turn_banners()

	if current_state == GameState.WAITING_INPUT:
		deck.start_draw_attention()


func _show_player_turn_banners() -> void:
	await _show_turn_banner(TURN_BANNER_TEXT)
	if _turnController.is_final_turn(current_turn, max_turns):
		await _show_turn_banner(FINAL_TURN_BANNER_TEXT)


func _show_turn_banner(text: String) -> void:
	if hud == null:
		return

	if turn_banner_tween != null and turn_banner_tween.is_running():
		turn_banner_tween.kill()

	if turn_banner != null:
		turn_banner.queue_free()
		turn_banner = null

	turn_banner = _create_turn_banner(text)
	hud.add_child(turn_banner)

	var label: Label = turn_banner.get_node("CenterContainer/TurnLabel") as Label
	label.scale = Vector2(0.72, 0.72)
	turn_banner.modulate = Color(1, 1, 1, 0)

	turn_banner_tween = create_tween()
	turn_banner_tween.set_parallel(true)
	turn_banner_tween.tween_property(turn_banner, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	turn_banner_tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	turn_banner_tween.chain().tween_interval(0.75)
	turn_banner_tween.chain().set_parallel(true)
	turn_banner_tween.tween_property(turn_banner, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	turn_banner_tween.tween_property(label, "scale", Vector2(1.22, 1.22), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await turn_banner_tween.finished
	_on_turn_banner_finished()

func _create_turn_banner(text: String) -> Control:
	var root: Control = Control.new()
	root.name = "TurnBanner"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var label: Label = Label.new()
	label.name = "TurnLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 92)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.48, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.018, 0.005, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 5)
	center.add_child(label)

	return root

func _on_turn_banner_finished() -> void:
	if turn_banner != null:
		turn_banner.queue_free()
		turn_banner = null
	turn_banner_tween = null

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	# Ir para menu principal, ou mudar de cena
	Globals.debug_log("on exit pressed")
	get_tree().change_scene_to_file("res://scenes/MenuGame.tscn")
	
func _reset_deck_and_timeline() -> void:
	pass
	#card_manager.reset_deck()
	#player_timeline.clear_timeline()
	#knowledge_clock.reset_clock()
