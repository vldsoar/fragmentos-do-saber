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
	#get_parent().connect_card_signals(self)
	Globals.debug_log("Card collision mask: %s" % $Area2D.collision_mask)

#func _on_area_2d_ready() -> void:
	#print("ready")
	#pass

func setup(card_data: CardResource, is_opponent: bool = false) -> void:
	_data = card_data
	_apply_theme()
	
	if self.has_node("Title"):
		self.get_node("Title").text = "[b] %s [/b]" % [_data.title]
		
	if self.has_node("Description"):
		self.get_node("Description").text = _data.description
	
	if self.has_node("Category"):
		self.get_node("Category").text = _data.category
	
	self.z_index = 1
	
	if is_opponent:
		self.position = Vector2(1820, 130)


func _apply_theme() -> void:
	if has_node("CardImage"):
		var card_image: Sprite2D = $CardImage
		var card_front: Texture2D = _get_card_front_texture()
		if card_front != null:
			card_image.texture = card_front
		CardVisualMetrics.apply_sprite_size(card_image)
		_apply_card_shader_theme(card_image)

	var body_font: Font = ThemeManager.get_font(ThemeManager.FONT_BODY)
	var bold_font: Font = ThemeManager.get_font(ThemeManager.FONT_CARD_BOLD)
	_apply_rich_text_theme("Title", ThemeManager.COLOR_CARD_TITLE, body_font, bold_font)
	_apply_rich_text_theme("Description", ThemeManager.COLOR_CARD_BODY, body_font, null)
	_apply_rich_text_theme("Category", ThemeManager.COLOR_CARD_CATEGORY, body_font, null)


func _apply_card_shader_theme(card_image: Sprite2D) -> void:
	if card_image == null or card_image.material == null:
		return

	var shader_material: ShaderMaterial = card_image.material as ShaderMaterial
	if shader_material == null:
		return

	var border_color: Color = ThemeManager.get_color(ThemeManager.COLOR_CARD_SHADER_BORDER, Color(0.101960786, 0.101960786, 0.101960786, 0.0))
	var background_color: Color = ThemeManager.get_color(ThemeManager.COLOR_CARD_SHADER_BACKGROUND, Color(0.490196, 0.223529, 0.00392157, 1.0))
	var border_width: float = float(ThemeManager.get_value(ThemeManager.VALUE_CARD_SHADER_BORDER_WIDTH, 8.0))
	shader_material.set_shader_parameter("border_color", border_color)
	shader_material.set_shader_parameter("background_color", background_color)
	shader_material.set_shader_parameter("border", border_width)


func _get_card_front_texture() -> Texture2D:
	if _data != null:
		var category_key: String = ThemeManager.texture_card_front_for_category(_data.category)
		var category_texture: Texture2D = ThemeManager.get_texture(category_key)
		if category_texture != null:
			return category_texture

	return ThemeManager.get_texture(ThemeManager.TEXTURE_CARD_FRONT)


func _apply_rich_text_theme(node_name: String, color_key: String, normal_font: Font, bold_font: Font) -> void:
	var label: RichTextLabel = get_node_or_null(node_name) as RichTextLabel
	if label == null:
		return

	label.modulate = ThemeManager.get_color(color_key, label.modulate)
	if normal_font != null:
		label.add_theme_font_override("normal_font", normal_font)
	if bold_font != null:
		label.add_theme_font_override("bold_font", bold_font)

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
		var card_back_texture: Texture2D = ThemeManager.get_texture(ThemeManager.TEXTURE_CARD_BACK)
		if card_back_texture == null:
			card_back_texture = preload("res://themes/default/images/card_back.png")
		var back = Sprite2D.new()
		back.name = "CardBackSprite"
		back.texture = card_back_texture
		CardVisualMetrics.apply_sprite_size(back)
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

func _on_area_2d_area_entered(area: Area2D) -> void:
	#print("area: entered")
	pass # Replace with function body.


func _on_area_2d_mouse_entered2() -> void:
	#print("mouse: entered 2")
	pass # Replace with function body.
