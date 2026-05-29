class_name PlayerTimeline
extends TimelineBase

const CARD_WIDTH = 160
const HAND_Y_POSITION = 950


func _ready() -> void:
	card_width = CARD_WIDTH
	hand_y_position = HAND_Y_POSITION
	hide_card_faces = false
	super._ready()
