extends Node2D

class_name GrapplingHook

var player : CharacterBody2D
var velocity : Vector2

signal hook_detached

@onready var rope : Line2D = $Rope
@onready var hook_sprite : Sprite2D = $HookSprite

enum State { Inactive, Flying, Reeling, Hooked }

var state : State = State.Flying

static var hooks = {}

const MAXIMUM_LENGTH = 3000
const FLYING_SPEED = 3200
const REELING_SPEED = 6400

func init(player):
	self.player = player
	player.hook = self
	
	hooks[player.id] = self

static func get_hook(player):
	if hooks.has(player.id):
		return hooks[player.id]
	return null
	
static func detach_hook(player):
	player.hook = null
		
	if hooks.has(player.id):
		hooks[player.id].queue_free()
		hooks.erase(player.id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hook_sprite.rotation = Vector2(0, -1).angle_to(self.velocity)
	
func _physics_process(delta: float) -> void:
	var new_position = self.global_position
	
	if not state == State.Hooked:
		if state == State.Reeling:
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
			state = State.Hooked
			hook_sprite.rotation = Vector2(0, 1).angle_to(result.normal)
		else:
			self.global_position = new_position
			
			var length = (player.global_position - self.global_position).length()
			
			if state == State.Reeling:
				if length < REELING_SPEED * delta:
					hook_detached.emit()	
					return
			elif length > MAXIMUM_LENGTH:
				state = State.Reeling

	rope.points[1] = player.global_position - self.global_position
