class_name BoardSlotGrid
extends Node2D

const SLOT_TEXTURE_PATH := "res://card_slot.png"
const SLOT_COUNT := 8
const COLUMNS := 4
const CARD_SCALE := 0.68
const GRID_SPACING := Vector2(150, 175)
const PLAYER_ORIGIN := Vector2(735, 570)
const OPPONENT_ORIGIN := Vector2(735, 170)


func _ready() -> void:
	_build_slots()


func _build_slots() -> void:
	var texture: Texture2D = load(SLOT_TEXTURE_PATH) as Texture2D
	if texture == null:
		push_warning("BoardSlotGrid: textura de slot nao encontrada em %s" % SLOT_TEXTURE_PATH)
		return

	for child: Node in get_children():
		child.queue_free()

	var origin: Vector2 = _get_origin()
	for index: int in range(SLOT_COUNT):
		var slot: Sprite2D = Sprite2D.new()
		slot.name = "BoardSlot%d" % (index + 1)
		slot.texture = texture
		slot.position = _get_slot_position(origin, index)
		slot.z_index = -1
		CardVisualMetrics.apply_sprite_size(slot, CardVisualMetrics.CARD_SIZE * CARD_SCALE)
		add_child(slot)


func _get_origin() -> Vector2:
	if name.to_lower().contains("opponent"):
		return OPPONENT_ORIGIN
	return PLAYER_ORIGIN


func _get_slot_position(origin: Vector2, index: int) -> Vector2:
	var col: int = index % COLUMNS
	var row: int = floori(float(index) / float(COLUMNS))
	return Vector2(
		origin.x + float(col) * GRID_SPACING.x,
		origin.y + float(row) * GRID_SPACING.y
	)
