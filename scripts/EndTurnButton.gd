extends Button

signal end_turn_requested

@onready var game_manager: GameManager = $"../../GameManager"

func _ready() -> void:
	# React to game state changes and keep visibility in sync.
	game_manager.fsm.state_changed.connect(_on_state_changed)
	_update_visibility(game_manager.current_state)
	pressed.connect(_on_pressed)

func _on_state_changed(_old_state: int, new_state: int) -> void:
	_update_visibility(new_state)

func _update_visibility(state: int) -> void:
	visible = state == GameManager.GameState.RESOLVE_ACTIONS

func _on_pressed() -> void:
	emit_signal("end_turn_requested")
