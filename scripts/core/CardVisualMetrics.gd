class_name CardVisualMetrics
extends RefCounted

const CARD_SIZE := Vector2(148.0, 222.0)


static func apply_sprite_size(sprite: Sprite2D, target_size: Vector2 = CARD_SIZE) -> void:
	if sprite == null or sprite.texture == null:
		return

	var texture_size: Vector2 = sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	sprite.scale = Vector2(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)
