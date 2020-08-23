extends RayCast2D


onready var line2d := get_node("Line2D")
onready var tween := get_node("Tween")
onready var beam_particles := get_node("BeamParticles")
onready var collision_particles := get_node("CollisionParticles")
onready var casting_particles := get_node("CastingParticles")

# Shooting variables

const beam_offset = 15
var cast_speed := 7000.0
var max_length := 200
var growth_time := 0.1
var ray_width := 5.0

var is_casting := false setget set_is_casting

var lines = []

func _ready():
	set_physics_process(false)
	line2d.points[0] = Vector2(beam_offset, 0)
	line2d.points[1] = Vector2(beam_offset, 0)
	
	print("Color", line2d.default_color)

func _physics_process(delta):
	cast_to = (cast_to + Vector2.RIGHT * cast_speed * delta).clamped(max_length)
	cast_beam()
	
func cast_beam() -> void:
	var cast_point := cast_to
	
	force_raycast_update()

	collision_particles.emitting = is_colliding()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = cast_point
		
		var collider = get_collider()
		if collider is TileMap:
			#get_parent().beam_collided(collider, get_collision_point())
			
			get_parent().beam_collided(collider, get_collision_point())
		
	line2d.points[1] = cast_point
	beam_particles.position = cast_point * 0.5
	beam_particles.process_material.emission_box_extents.x = cast_point.length() * 0.5
	
func start_casting(color : Color):
	set_color(color)
	set_is_casting(true)

func stop_casting():
	set_is_casting(false)
	
func set_is_casting(cast: bool):
	is_casting = cast
	
	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting
	if is_casting:
		appear()
	else:
		collision_particles.emitting = false
		disappear()
		
	set_physics_process(is_casting)
	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting

func set_color(color : Color):
	line2d.default_color = color
	var gradient = casting_particles.process_material.get_color_ramp().get_gradient()
	gradient.set_colors([color, color, Color(0, 0, 0, 0)])
	casting_particles.process_material.get_color_ramp().set_gradient(gradient)
	collision_particles.process_material.get_color_ramp().set_gradient(gradient)
	#beam_particles.process_material.get_color_ramp().set_gradient(gradient)
	

func appear() -> void:
	tween.stop_all()
	tween.interpolate_property(line2d, "width", 0, ray_width, growth_time * 2)
	tween.start()
	
func disappear() -> void:
	tween.stop_all()
	tween.interpolate_property(line2d, "width", ray_width, 0, growth_time)
	tween.start()
