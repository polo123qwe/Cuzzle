extends Node2D

enum TILES {EMPTY, FULL, RED, GREEN, BLUE, WHITE, 
			COLORED_RED, COLORED_GREEN, COLORED_BLUE, COLORED_WHITE, 
			RED_KEY, GREEN_KEY, BLUE_KEY, WHITE_KEY, 
			BREAKABLE_RED, BREAKABLE_GREEN, BREAKABLE_BLUE, BREAKABLE_WHITE,
			DOOR_CLOSED_RED, DOOR_CLOSED_GREEN, DOOR_CLOSED_BLUE, DOOR_CLOSED_WHITE,
			DOOR_OPEN_RED, DOOR_OPEN_GREEN, DOOR_OPEN_BLUE, DOOR_OPEN_WHITE, SAVE}

onready var tilemap := $TileMap
onready var player := $Player
onready var start_menu_background := $StartMenuBackground
onready var start_game_button := get_node("StartMenuBackground/StartMenu/StartGame")
onready var volume_button := get_node("StartMenuBackground/StartMenu/Volume")
onready var label := get_node("StartMenuBackground/StartMenu/Label")

var game_started = false

var lines = []

var starting_tilemap_cells = {}
var starting_player_position

var current_checkpoint

class Checkpoint:
	var cords
	var modified_tiles = {}
	var active_color
	
	var player_red_key
	var player_green_key
	var player_blue_key
	
	func _init(_cords : Vector2, _active_color : Color, _player_red_key : bool, 
				_player_green_key : bool, _player_blue_key : bool):
		cords = _cords
		active_color = _active_color
		player_red_key = _player_red_key
		player_green_key = _player_green_key
		player_blue_key = _player_blue_key
		
	func add_tile_modification(cellv : Vector2, original_value : int):
		modified_tiles[cellv] = original_value

func _ready():
	for cell in tilemap.get_used_cells():
		starting_tilemap_cells[cell] = tilemap.get_cellv(cell)
		
	starting_player_position = player.position
	
	player.connect('restart_game', self, '_restart_game')
	player.connect('load_checkpoint', self, '_load_checkpoint')
	
	start_game_button.connect("pressed", self, "_game_start")
	volume_button.connect("toggled", self, "_toggle_volume")
	
func _game_start():
	start_menu_background.hide()
	label.hide()
	start_game_button.hide()
	volume_button.hide()
	
	game_started = true
	player.disable_input = false
	
func _toggle_volume(toggle : bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggle)

func _physics_process(_delta):
	if not game_started:
		return  
	check_color_change()
	
	check_player_position()
	
	check_door_collision()
	
func check_color_change():
	if not player.get_node("GroundRaycast").is_colliding():
		return
		
	var cell = get_tilemap_cell(player.get_node("GroundRaycast").get_collision_point() + Vector2.DOWN)
	
	if cell.value > TILES.FULL and cell.value <= TILES.WHITE:
		player.update_color(cell.value)

func check_player_position():
	var cords = tilemap.world_to_map(player.position)
	
	var cell = tilemap.get_cellv(cords)
	
	# Player is picking up a key
	if cell in [TILES.RED_KEY, TILES.GREEN_KEY, TILES.BLUE_KEY]:
		player.add_key(cell)
		
		checkpoint_save_cell_value(cords, cell)
		tilemap.set_cellv(cords, -1)
		
		get_node("Sounds/KeyPickedUp").play()
	
	# Player is reaching a checkpoint
	if cell == TILES.SAVE:
		save_checkpoint(cords)
	
# CHECKPOINT METHODS

func save_checkpoint(checkpoint_cords):
	if current_checkpoint and current_checkpoint.cords == checkpoint_cords:
		return
		
	current_checkpoint = Checkpoint.new(checkpoint_cords, player.active_color, player.red_key, player.green_key, player.blue_key)
	player.reached_checkpoint()
	get_node("Sounds/Checkpoint").play()
	
func checkpoint_save_cell_value(pos : Vector2, cell : int):
	if current_checkpoint:
		current_checkpoint.add_tile_modification(pos, cell)

func _load_checkpoint():
	if not current_checkpoint:
		return
	
	player.position = tilemap.map_to_world(current_checkpoint.cords)
	player.red_key = current_checkpoint.player_red_key
	player.green_key = current_checkpoint.player_green_key
	player.blue_key = current_checkpoint.player_blue_key
	
	for cell_data in current_checkpoint.modified_tiles:
		tilemap.set_cellv(cell_data, current_checkpoint.modified_tiles[cell_data])
	
	if current_checkpoint.active_color == Color.red:
		player.update_color(TILES.RED)
	if current_checkpoint.active_color == Color.green:
		player.update_color(TILES.GREEN)
	if current_checkpoint.active_color == Color.blue:
		player.update_color(TILES.BLUE)
	if current_checkpoint.active_color == Color.white:
		player.update_color(TILES.WHITE)
	
#########################################

func check_door_collision():
	var left_raycast := player.get_node("LeftRaycast")
	var right_raycast := player.get_node("RightRaycast")
	var cell
	
	if left_raycast.is_colliding():
		cell = get_tilemap_cell(left_raycast.get_collision_point() + Vector2.LEFT)
		
	if right_raycast.is_colliding():
		cell = get_tilemap_cell(right_raycast.get_collision_point() + Vector2.RIGHT)
		
	if cell and cell.value in [TILES.DOOR_CLOSED_RED, TILES.DOOR_CLOSED_GREEN, TILES.DOOR_CLOSED_BLUE]:
		player.try_door_unlock(tilemap, cell)

func get_tilemap_cell(world_point : Vector2):
	var cords = tilemap.world_to_map(world_point)
	
	return {'value': tilemap.get_cellv(cords), 'cords': cords}

func debug_line(start : Vector2, end : Vector2, color = Color.purple):
	lines.append({'start': start, 'end': end, 'color': color})
	update()

func _draw():
	for line in lines:
		draw_line(line.start, line.end, line.color, 2.0)
		
func _restart_game():
	player.position = starting_player_position
	for cell_data in starting_tilemap_cells:
		tilemap.set_cellv(cell_data, starting_tilemap_cells[cell_data])
