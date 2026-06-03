class_name OpponentTimeline
extends TimelineBase

const BOARD_CAPACITY := 8
const BOARD_CARD_SCALE := Vector2(0.68, 0.68)
const BOARD_COLUMNS := 4
const BOARD_ORIGIN := Vector2(735, 170)
const BOARD_SPACING := Vector2(150, 175)


func _ready() -> void:
	max_cards = BOARD_CAPACITY
	card_scale = BOARD_CARD_SCALE
	use_grid_layout = true
	grid_columns = BOARD_COLUMNS
	grid_origin = BOARD_ORIGIN
	grid_spacing = BOARD_SPACING
	hide_card_faces = true
	super._ready()


func calculate_card_position_for_index(index: int) -> Vector2:
	var visual_index: int = (BOARD_CAPACITY - 1) - index
	var col: int = visual_index % BOARD_COLUMNS
	var row: int = floori(float(visual_index) / float(BOARD_COLUMNS))
	return Vector2(
		BOARD_ORIGIN.x + float(col) * BOARD_SPACING.x,
		BOARD_ORIGIN.y + float(row) * BOARD_SPACING.y
	)
