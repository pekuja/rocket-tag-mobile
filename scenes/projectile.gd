extends Node2D

class_name Projectile

@export var velocity = Vector2(0,1)
@export var lifetime = 1.0

signal projectile_impact(projectile)
signal projectile_expired(projectile)

var player : PlayerCharacter
var id : int = -1

var _time_created = 0

func _ready() -> void:
	_time_created = Time.get_ticks_msec()
	
	rotation = Vector2(0, -1).angle_to(velocity)

func _physics_process(delta: float) -> void:
	var new_position = global_position + velocity * delta
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(self.global_position, new_position)
	query.exclude = [player]
	var result = space_state.intersect_ray(query)
	
	if result:
		projectile_impact.emit(self)
		print("Projectile hit something")
	
	global_position = new_position
	
	if Time.get_ticks_msec() - _time_created > 1000 * lifetime:
		self.queue_free()
		projectile_expired.emit(self)
		print("Projectile expired")
