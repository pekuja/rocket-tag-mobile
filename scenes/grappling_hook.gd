extends Node2D

var player : CharacterBody2D
var velocity : Vector2

signal hook_detached

@onready var rope : Line2D = $Rope
@onready var hook : Sprite2D = $HookSprite

var is_hooked = false
var is_reeling = false

const MAXIMUM_LENGTH = 2000
const REELING_SPEED = 2000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hook.rotation = Vector2(0, -1).angle_to(self.velocity)
	
func _physics_process(delta: float) -> void:
	var new_position = self.global_position
	
	if not is_hooked:
		if is_reeling:
			var direction = (player.global_position - self.position).normalized()
			new_position = self.global_position + direction * REELING_SPEED * delta
		else:
			new_position = self.global_position + self.velocity * delta
		
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(self.global_position, new_position)
		query.exclude = [player]
		var result = space_state.intersect_ray(query)
		
		if result:
			self.global_position = result.position
			is_hooked = true
			hook.rotation = Vector2(0, 1).angle_to(result.normal)
		else:
			self.global_position = new_position
			
			var length = (player.global_position - self.global_position).length()
			
			if is_reeling:
				if length < REELING_SPEED * delta:
					queue_free()
					hook_detached.emit()	
					return
			elif length > MAXIMUM_LENGTH:
				is_reeling = true

	rope.points[1] = player.global_position - self.global_position
