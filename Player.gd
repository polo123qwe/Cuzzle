extends KinematicBody2D

# General variables

signal restart_game
signal load_checkpoint

enum TILES {EMPTY, FULL, RED, GREEN, BLUE, WHITE, 
			COLORED_RED, COLORED_GREEN, COLORED_BLUE, COLORED_WHITE, 
			RED_KEY, GREEN_KEY, BLUE_KEY, WHITE_KEY, 
			BREAKABLE_RED, BREAKABLE_GREEN, BREAKABLE_BLUE, BREAKABLE_WHITE,
			DOOR_CLOSED_RED, DOOR_CLOSED_GREEN, DOOR_CLOSED_BLUE, DOOR_CLOSED_WHITE,
			DOOR_OPEN_RED, DOOR_OPEN_GREEN, DOOR_OPEN_BLUE, DOOR_OPEN_WHITE, SAVE}
enum COLLISION_MASK {ENVIRONMENT, PLAYER, ENEMY, RED, GREEN, BLUE, WHITE}

# Movement variables 

var move_speed = 200
var jump_speed = -400
var gravity = 1200

var velocity = Vector2()
var jumping = false

var disable_input = true

# Node variables

onready var animated_sprite = get_node("AnimatedSprite")
onready var weapon_raycast = get_node("WeaponRaycast")
onready var ground_raycast = get_node("GroundRaycast")
onready var ui = get_node("UI")
onready var walking_sound = get_node("WalkingSound")
onready var jumping_sound = get_node("JumpingSound")

# Attack variables

var color_red_attack := Color.red.blend(Color(3.0, 0, 0))
var color_green_attack := Color.green.blend(Color(0, 3.0, 0))
var color_blue_attack := Color.blue.blend(Color(0, 0, 3.0))
var color_white_attack := Color(2.0, 2.0, 2.0)

var active_color := Color.white
var active_color_attack := color_white_attack

var color_changed := false

# Pickups

var red_key := false
var green_key := false
var blue_key := false

func add_key(value):
	if value == TILES.RED_KEY:
		red_key = true
		ui.display_red_key()
	if value == TILES.GREEN_KEY:
		green_key = true
		ui.display_green_key()
	if value == TILES.BLUE_KEY:
		blue_key = true
		ui.display_blue_key()

func remove_key(value):
	pass
	if value == TILES.RED_KEY:
		red_key = false
		ui.hide_red_key()
	if value == TILES.GREEN_KEY:
		green_key = false
		ui.hide_green_key()
	if value == TILES.BLUE_KEY:
		blue_key = false
		ui.hide_blue_key()

func reset():
	update_color(TILES.WHITE)
	red_key = false
	green_key = false
	blue_key = false
	
	ui.hide_red_key()
	ui.hide_green_key()
	ui.hide_blue_key()

func try_door_unlock(tilemap : TileMap, cell):
	match cell.value:
		TILES.DOOR_CLOSED_RED:
			if red_key:
				checkpoint_save_cell_value(cell.cords, cell.value)
				tilemap.set_cellv(cell.cords, TILES.DOOR_OPEN_RED)
				red_key = false
				ui.hide_red_key()
		TILES.DOOR_CLOSED_GREEN:
			if green_key:
				checkpoint_save_cell_value(cell.cords, cell.value)
				tilemap.set_cellv(cell.cords, TILES.DOOR_OPEN_GREEN)
				green_key = false
				ui.hide_green_key()
		TILES.DOOR_CLOSED_BLUE:
			if blue_key:
				checkpoint_save_cell_value(cell.cords, cell.value)
				tilemap.set_cellv(cell.cords, TILES.DOOR_OPEN_BLUE)
				blue_key = false
				ui.hide_blue_key()

func checkpoint_save_cell_value(pos : Vector2, cell : int):
	if get_parent().has_method('checkpoint_save_cell_value'):
		get_parent().checkpoint_save_cell_value(pos, cell)

func _physics_process(delta):
	if disable_input:
		return
	
	velocity.x = 0
	
	handle_ui_input()
	
	update_movement()
	
	velocity.y += gravity * delta
	
	update_sprite()
	
	update_sound()
	
	velocity = move_and_slide(velocity, Vector2.UP)

	if jumping and is_on_floor():
		jumping = false
		
	weapon_raycast.look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("shoot"):
		weapon_raycast.start_casting(active_color_attack)
		
	if Input.is_action_just_released("shoot"):
		if weapon_raycast.is_casting:
			weapon_raycast.stop_casting()
		
		
func handle_ui_input():
	if Input.is_action_pressed("restart"):
		emit_signal("restart_game")
		reset()
		
	if Input.is_action_just_pressed("load_checkpoint"):
		emit_signal("load_checkpoint")
		
func update_sound():
	if is_on_floor():
		if not walking_sound.playing:
			if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
				walking_sound.play()
				
		if Input.is_action_just_pressed("up"):
			jumping_sound.play()
	else:
		walking_sound.stop()
	
	if Input.is_action_just_released("left") or Input.is_action_just_released("right"):
		walking_sound.stop()
		
func update_movement():
	if Input.is_action_pressed("left"):
		velocity.x -= move_speed
		animated_sprite.flip_h = true
		
	if Input.is_action_pressed("right"):
		velocity.x += move_speed
		animated_sprite.flip_h = false
	
	if is_on_floor() and Input.is_action_just_pressed("up"):
		velocity.y += jump_speed
		jumping = true

func update_sprite():
	animated_sprite.modulate = active_color
	
	if jumping:
		animated_sprite.play("jumping")
	elif velocity.x:
		animated_sprite.play("moving")
	else:
		animated_sprite.play("idle")
		

func update_color(tile_color : int):
	if tile_color == TILES.RED and active_color != Color.red:
		active_color = Color.red
		active_color_attack = color_red_attack
		set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.RED))
		weapon_raycast.set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.RED))
		color_changed = true
	
	if tile_color == TILES.GREEN and active_color != Color.green:
		active_color = Color.green
		active_color_attack = color_green_attack
		set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.GREEN))
		weapon_raycast.set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.GREEN))
		color_changed = true

	if tile_color == TILES.BLUE and active_color != Color.blue:
		active_color = Color.blue
		active_color_attack = color_blue_attack
		set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.BLUE))
		weapon_raycast.set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.BLUE))
		color_changed = true
	
	if tile_color == TILES.WHITE and active_color != Color.white:
		active_color = Color.white
		active_color_attack = color_white_attack
		set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.WHITE))
		weapon_raycast.set_collision_mask(pow(2, COLLISION_MASK.ENVIRONMENT) + pow(2, COLLISION_MASK.WHITE))
		color_changed = true
		
	if color_changed and not $ColorChanged.playing:
		$ColorChanged.play()
		if weapon_raycast.is_casting:
			weapon_raycast.stop_casting()
		
		color_changed = false

func beam_collided(tilemap : TileMap, collision_point : Vector2):
	var cell_cord = tilemap.world_to_map((collision_point - position) * .05 + collision_point)
	var cell = tilemap.get_cellv(cell_cord)
	
	#if get_parent().has_method("debug_line"):
		#get_parent().debug_line(position, collision_point, Color.purple)
		#get_parent().debug_line(position, (collision_point - position) * .1 + collision_point, Color.yellow)
	
	# Break the breakable blocks if color matches
	if cell == TILES.BREAKABLE_RED and active_color == Color.red:
		checkpoint_save_cell_value(cell_cord, cell)
		tilemap.set_cellv(cell_cord, -1)
	if cell == TILES.BREAKABLE_GREEN and active_color == Color.green:
		checkpoint_save_cell_value(cell_cord, cell)
		tilemap.set_cellv(cell_cord, -1)
	if cell == TILES.BREAKABLE_BLUE and active_color == Color.blue:
		checkpoint_save_cell_value(cell_cord, cell)
		tilemap.set_cellv(cell_cord, -1)

func reached_checkpoint():
	ui.checkpoint_label_trigger()
