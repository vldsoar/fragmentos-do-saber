class_name KnowledgeClock
extends Node2D

@export var max_turn_time: float = 10.0  # só para referência, se quiser

@onready var sand_top: ColorRect = $RotationsParts/SandTop
@onready var sand_bottom: ColorRect = $RotationsParts/SandBottom
@onready var turn_label: Label = $TurnLabel
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Começa com areia toda em cima
	set_progress(0.0)
	set_turn(1)

func set_turn(turn: int) -> void:
	turn_label.text = str(turn)

# progress ∈ [0.0, 1.0] – 0 = começo do turno, 1 = fim do turno
func set_progress(progress: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	Globals.debug_log("KnowledgeClock progress: %s" % p)
	# Exemplo simples: escala vertical da areia
	sand_top.scale.y = 1.0 - p
	sand_bottom.scale.y = p

func flip() -> void:
	if anim:
		anim.play("flip")
