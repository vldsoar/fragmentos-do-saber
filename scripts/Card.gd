class_name CardScn
extends Node2D

signal hovered
signal hovered_off

var start_position
var _data: CardResource
#@export var revealed_on_spawn: bool = false
var _is_revealed: bool = false  # When true, card does not respond to interactions
var _is_flipped: bool = false  # When true, card shows back instead of front

var is_revealed: bool:
	get:
		return _is_revealed

var rarity: CardResource.Rarity:
	get:
		return _data.rarity

var effect: CardResource.SpecialEffect:
	get:
		return _data.effect

@export var data: CardResource: get = _get_data

# Variables to manage tweens
#var tween_hover: Tween

func _ready() -> void:
	# All cards are children of CardManager, so we can get the parent and connect the signals
	get_parent().connect_card_signals(self)
	Globals.debug_log("Card collision mask: %s" % $Area2D.collision_mask)

#func _on_area_2d_ready() -> void:
	#print("ready")
	#pass

func setup(card_data: CardResource, is_opponent: bool = false) -> void:
	_data = card_data
	
	if self.has_node("Title"):
		self.get_node("Title").text = "[b] %s [/b]" % [_data.title]
		
	if self.has_node("Description"):
		self.get_node("Description").text = _data.description
	
	if self.has_node("Category"):
		self.get_node("Category").text = _data.category
	
	self.z_index = 1
	
	if is_opponent:
		self.position = Vector2(1820, 130)

func _get_data() -> CardResource:
	return _data

func _on_area_2d_mouse_entered() -> void:
	# if is_revealed:
	# 	return
	Globals.debug_log("Card hovered: entered")
	
	emit_signal("hovered", self)
	
	
	#
	#if tween_hover and tween_hover.is_running():
		#tween_hover.kill()
	## Reset scale
	#tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	#tween_hover.tween_property(self, "scale", Vector2(1.5, 1.5), 0.5)

func _on_area_2d_mouse_exited() -> void:
	# if is_revealed:
	# 	return
	
	emit_signal("hovered_off", self)
	Globals.debug_log("Card hovered: exited")
	
	#if tween_hover and tween_hover.is_running():
		#tween_hover.kill()
	## Reset scale
	#tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	#tween_hover.tween_property(self, "scale", Vector2.ONE, 0.5)

func disable_collision() -> void:
	Globals.debug_log("Disabling card collision")
	get_node("Area2D/CollisionShape2D").disabled = true
	
func enable_collision() -> void:
	get_node("Area2D/CollisionShape2D").disabled = false

func set_as_revealed() -> void:
	_is_revealed = true
	# Disable collision to avoid accidental interactions
	disable_collision()

func disable_as_revealed() -> void:
	_is_revealed = false
	enable_collision()

func is_special() -> bool:
	return _data.rarity == CardResource.Rarity.SPECIAL

func is_flipped() -> bool:
	return _is_flipped

func flip_to_back() -> void:
	_is_flipped = true
	# Esconder elementos da face
	if has_node("Title"):
		$Title.visible = false
	if has_node("Description"):
		$Description.visible = false
	if has_node("Category"):
		$Category.visible = false
	if has_node("CardImage"):
		$CardImage.visible = false
	
	# Mostrar verso (criar se não existir)
	if not has_node("CardBackSprite"):
		var card_back_texture = preload("res://card_back_3.png")
		var back = Sprite2D.new()
		back.name = "CardBackSprite"
		back.texture = card_back_texture
		back.scale = Vector2(0.148, 0.154167)  # Mesmo scale do CardImage
		back.z_index = 10  # Garantir que fique acima
		add_child(back)
	
	if has_node("CardBackSprite"):
		$CardBackSprite.visible = true

func flip_to_front() -> void:
	_is_flipped = false
	# Mostrar elementos da face
	if has_node("Title"):
		$Title.visible = true
	if has_node("Description"):
		$Description.visible = true
	if has_node("Category"):
		$Category.visible = true
	if has_node("CardImage"):
		$CardImage.visible = true
	
	# Esconder verso
	if has_node("CardBackSprite"):
		$CardBackSprite.visible = false

#func _on_area_2d_area_entered(area: Area2D) -> void:
	#print("area: entered")
	#pass # Replace with function body.
#
#
#func _on_area_2d_mouse_entered2() -> void:
	#print("mouse: entered 2")
	#pass # Replace with function body.
