extends Node2D

@export var moveInput : TouchJoystick
@export var shootInput : TouchJoystick

@export var projectileNode : PackedScene
@export var projectileSpeed = 400.0

@onready var character = $Character
@onready var _animation_player = $Character/AnimatedSprite2D
#@onready var _sprite_ship = $Character/ShipSprite
@onready var _projectile_spawn_point = $Character/GunSprite/ProjectileSpawnPoint
@onready var _sprite_gun = $Character/GunSprite
@onready var _arrow = $Line2D

signal projectile_shot(position, direction)

const SPEED = 300.0
const ACCELERATE = 1200.0
const DECELERATE = 100.0
const SHOOT_THRESHOLD = 0.5
const ROTATE_SPEED = 6.28

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if moveInput.is_pressed:
		_animation_player.play("walk")
		character.velocity = character.velocity.move_toward(moveInput.joystick_position * SPEED, ACCELERATE * delta)
		
		if character.velocity.x < 0:
			_animation_player.flip_h = true
		else:
			_animation_player.flip_h = false
	else:
		_animation_player.stop()
		character.velocity = character.velocity.move_toward(Vector2(0,0), DECELERATE * delta)

	character.move_and_slide()
	
func _process(delta: float) -> void:
	_arrow.position = character.position
	if shootInput.is_just_released:
		var direction = shootInput.joystick_position
		if direction.length() > SHOOT_THRESHOLD:
			direction = direction.normalized()
			var projectile = projectileNode.instantiate()
			
			projectile.velocity = direction * projectileSpeed
			projectile.lifetime = 1.0
			
			get_parent().add_child(projectile)
			
			projectile.global_position = _projectile_spawn_point.global_position
			
			projectile_shot.emit(projectile.global_position, direction)
	
	if moveInput.is_pressed:
		var target_rotation = Vector2(0, -1).angle_to(moveInput.joystick_position)
		var angle_diff = angle_difference(character.rotation, target_rotation)
		character.rotation = move_toward(character.rotation, character.rotation + angle_diff, ROTATE_SPEED * delta)
		_arrow.rotation = target_rotation
	if shootInput.is_pressed and shootInput.joystick_position.length() > SHOOT_THRESHOLD:
		_sprite_gun.global_rotation = Vector2(0, -1).angle_to(shootInput.joystick_position)
