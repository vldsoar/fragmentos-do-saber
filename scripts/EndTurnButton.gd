extends Button

signal end_turn_requested

@onready var game_manager: GameManager = $"../../GameManager"

func _ready() -> void:
	ThemeManager.apply_button(self)
	# React to game state changes and keep visibility in sync.
	game_manager.fsm.state_changed.connect(_on_state_changed)
	game_manager.card_reveal_panel.reveal_state_changed.connect(_on_reveal_state_changed)
	game_manager.player_hand.hand_size_changed.connect(_on_hand_size_changed)
	_update_visibility(game_manager.current_state)
	pressed.connect(_on_pressed)

func _on_state_changed(_old_state: int, new_state: int) -> void:
	_update_visibility(new_state)

func _on_reveal_state_changed(_active: bool) -> void:
	_update_visibility(game_manager.current_state)

func _on_hand_size_changed(_size: int) -> void:
	_update_visibility(game_manager.current_state)

func _update_visibility(state: int) -> void:
	visible = state == GameManager.GameState.RESOLVE_ACTIONS
	disabled = not game_manager.can_end_player_turn()

func _on_pressed() -> void:
	if disabled:
		return
	emit_signal("end_turn_requested")
