extends Node2D

class_name Projectile

@export var velocity = Vector2(0,1)
@export var lifetime = 1.0

var _time_created = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_time_created = Time.get_ticks_msec()
	
	rotation = Vector2(0, -1).angle_to(velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	if Time.get_ticks_msec() - _time_created > 1000 * lifetime:
		self.queue_free()
