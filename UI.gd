extends Node2D

const WIDTH = 256 # The camera size
const HEIGHT = 150 # The camera size
const MARGIN = 6
const SPRITE_SIZE = 16

# Tween options

const ORIGINAL_Y_POS = -16
const ORIGINAL_SCALE = Vector2(.3, .3)
const OFFSET_SCALE = Vector2(.4, .4)
const TWEEN_TIME = 0.7


onready var color_rect = $ColorRect
onready var checkpoint_label = $CheckpointLabel
onready var tween = $Tween

var tiles_colored = preload("res://Assets/Tilesheet/tiles_interactive.png")
var shader = preload("res://Outline.shader")

var red_sprite
var green_sprite
var blue_sprite

var player_red_keys = 0
var player_green_keys = 0
var player_blue_keys = 0

func _ready():
	var shaderMat = ShaderMaterial.new()
	shaderMat.shader = shader
	
	red_sprite = Sprite.new()
	red_sprite.texture = tiles_colored
	red_sprite.region_enabled = true
	red_sprite.region_rect = Rect2(0, 0, SPRITE_SIZE, SPRITE_SIZE)
	red_sprite.position = Vector2(WIDTH - MARGIN - SPRITE_SIZE, HEIGHT - MARGIN - SPRITE_SIZE)
	red_sprite.material = shaderMat
	red_sprite.visible = false
	add_child(red_sprite)
	
	green_sprite = Sprite.new()
	green_sprite.texture = tiles_colored
	green_sprite.region_enabled = true
	green_sprite.region_rect = Rect2(16, 0, SPRITE_SIZE, SPRITE_SIZE)
	green_sprite.position = Vector2(WIDTH - MARGIN * 2 - SPRITE_SIZE * 2, HEIGHT - MARGIN - SPRITE_SIZE)
	green_sprite.material = shaderMat
	green_sprite.visible = false
	add_child(green_sprite)
	
	blue_sprite = Sprite.new()
	blue_sprite.texture = tiles_colored
	blue_sprite.region_enabled = true
	blue_sprite.region_rect = Rect2(32, 0, SPRITE_SIZE, SPRITE_SIZE)
	blue_sprite.position = Vector2(WIDTH - MARGIN * 3 - SPRITE_SIZE * 3, HEIGHT - MARGIN - SPRITE_SIZE)
	blue_sprite.material = shaderMat
	blue_sprite.visible = false
	add_child(blue_sprite)
	
	color_rect.margin_top = HEIGHT - MARGIN * 3 - SPRITE_SIZE
	color_rect.margin_left = WIDTH - MARGIN * 6 - SPRITE_SIZE * 3
	color_rect.margin_bottom = color_rect.margin_top + MARGIN * 2 + SPRITE_SIZE
	color_rect.margin_right = color_rect.margin_left + MARGIN * 5 + SPRITE_SIZE * 3
	
	tween.connect("tween_all_completed", self, "_tween_all_completed")

func display_red_key():
	red_sprite.visible = true
	
func display_green_key():
	green_sprite.visible = true
	
func display_blue_key():
	blue_sprite.visible = true
	
func hide_red_key():
	red_sprite.visible = false
	
func hide_green_key():
	green_sprite.visible = false
	
func hide_blue_key():
	blue_sprite.visible = false

func checkpoint_label_trigger() -> void:
	reset_checkpoint_label()
	checkpoint_label.visible = true
	
	var start_pos = checkpoint_label.rect_position.y
	var end_pos = checkpoint_label.rect_position.y - 8
	
	tween.stop_all()
	tween.interpolate_property(checkpoint_label, "modulate:a", 1.0, 0, TWEEN_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(checkpoint_label, "rect_position:y", start_pos, end_pos, TWEEN_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(checkpoint_label, "rect_scale", ORIGINAL_SCALE, OFFSET_SCALE, TWEEN_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()

func _tween_all_completed():
	checkpoint_label.visible = false
	reset_checkpoint_label()
	
func reset_checkpoint_label():
	checkpoint_label.modulate.a = 1
	checkpoint_label.rect_position.y = ORIGINAL_Y_POS
	checkpoint_label.rect_scale = ORIGINAL_SCALE
	
