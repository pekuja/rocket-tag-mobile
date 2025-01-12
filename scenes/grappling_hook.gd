extends Node2D

var player : CharacterBody2D
var velocity : Vector2

@onready var rope : Line2D = $Rope
@onready var hook : Sprite2D = $HookSprite

var is_hooked = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hook.rotation = Vector2(0, -1).angle_to(self.velocity)
	
func _physics_process(delta: float) -> void:
	if not is_hooked:
		var new_position = self.global_position + self.velocity * delta
		
		var space_state = get_world_2d().direct_space_state
		
		# use global coordinates, not local to node
		var query = PhysicsRayQueryParameters2D.create(self.position, new_position)
		query.exclude = [player]
		var result = space_state.intersect_ray(query)
		
		if result:
			self.position = result.position
			is_hooked = true
			hook.rotation = Vector2(0, 1).angle_to(result.normal)
		else:
			self.global_position = new_position

	rope.points[1] = player.global_position - self.position
