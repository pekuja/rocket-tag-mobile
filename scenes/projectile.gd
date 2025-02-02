extends Node2D

class_name Projectile

@export var velocity = Vector2(0,1)
@export var lifetime = 1.0

signal projectile_impact(position)
signal projectile_expired()

var player : PlayerCharacter

var _time_created = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_time_created = Time.get_ticks_msec()
	
	rotation = Vector2(0, -1).angle_to(velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var new_position = global_position + velocity * delta
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(self.global_position, new_position)
	query.exclude = [player]
	var result = space_state.intersect_ray(query)
	
	if result:
		projectile_impact.emit(result.position)
	
	global_position += new_position
	
	if Time.get_ticks_msec() - _time_created > 1000 * lifetime:
		self.queue_free()
		projectile_expired.emit()
