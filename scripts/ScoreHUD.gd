class_name ScoreHUD
extends Control

@onready var score_label: Label = $ScoreLabel

var score: int = 0:
	set(value):
		score = value
		_update_score_label()

func _ready() -> void:
	_update_score_label()

func add_points(amount: int) -> void:
	score += amount
	_update_score_label()

func set_score(value: int) -> void:
	score = value
	_update_score_label()

func _update_score_label() -> void:
	if score_label:
		score_label.text = "%d" % score
