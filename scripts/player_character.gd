extends CharacterBody2D

class_name PlayerCharacter

@export var sprite_frame_options: Array[SpriteFrames]

@onready var _animation_player = $AnimatedSprite2D
@onready var _healthbar = $HealthBar
@onready var _collision_shape = $CollisionShape2D
@onready var projectile_spawn_point = $GunSprite/ProjectileSpawnPoint

signal player_died(victim: PlayerCharacter, killer : PlayerCharacter)

var hook : Node2D
var last_hook_state : GrapplingHook.State = GrapplingHook.State.Inactive
var projectiles = {}
var id = -1

var health = 100
var respawn_timer = 0.0

var score = 0

var sprite_frame_index = 0

const SPEED = 300.0
const ACCELERATE = 1200.0
const DECELERATE = 800.0
const HOOK_THRESHOLD = 0.5
const SHOOT_THRESHOLD = 0.5
const ROTATE_SPEED = 6.28
const TERMINAL_VELOCITY = 1200.0

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")

func update_sprite():
	sprite_frame_index = 0
	if sprite_frame_options.size() > 0 and id >= 0:
		sprite_frame_index = id % sprite_frame_options.size()
	else:
		print("id: ", id, " and number of sprite frames", sprite_frame_options.size())
	
	_animation_player.sprite_frames = sprite_frame_options[sprite_frame_index]
	
func is_alive():
	return health > 0

func _physics_process(delta: float) -> void:
	if health == 0:
		return
	
	# TODO? Could introduce some kind of free movement, but for now I'm relying on just grappling hook.
	#if moveInput.is_pressed and character.is_on_floor():
		#character.velocity.x = move_toward(character.velocity.x, moveInput.joystick_position.x * SPEED, ACCELERATE * delta)
			
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATE * delta)

	if hook and hook.state == GrapplingHook.State.Hooked:
		#hacky magnitude
		var direction = (hook.global_position - global_position).normalized()
		var magnitude = minf((hook.global_position - global_position).length() * 5, 5000)
		velocity = velocity.move_toward(direction * TERMINAL_VELOCITY * 2, magnitude * delta)

	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

	move_and_slide()

func _process(_delta: float) -> void:
	if health == 0:
		visible = false
		_collision_shape.disabled = true
		if hook:
			GrapplingHook.detach_hook(self)
	else:
		visible = true
		_collision_shape.disabled = false
		
		if velocity.x < 0:
			_animation_player.flip_h = true
		else:
			_animation_player.flip_h = false
		
		if abs(velocity.x) > 0 and is_on_floor():
			_animation_player.play("walk")
		elif not is_on_floor():
			_animation_player.play("jump")
		else:
			_animation_player.play("stand")
		
func explosion_hit(explosion_owner : PlayerCharacter, pos : Vector2):
	if is_multiplayer_authority() and health > 0:
		var diff = global_position - pos
		
		var force_magnitude = 100000.0 / diff.length()
		var force_direction = diff.normalized()
		
		velocity += force_magnitude * force_direction
			
		var damage = round(5000 / diff.length())
		if damage > 0:
			health = clamp(health - damage, 0, 100)
		
			on_damage_taken()
			update_healthbar()
			
			if health == 0:
				player_died.emit(self, explosion_owner)
		
func update_healthbar():
	_healthbar.points[1].x = health

func on_damage_taken():
	_animation_player.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(_animation_player, "modulate", Color.WHITE, 0.5)
	
	
