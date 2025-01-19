extends Node2D

class_name LocalPlayer

@export var moveInput : TouchJoystick
@export var shootInput : TouchJoystick

@export var projectileScene : PackedScene
@export var projectileSpeed = 400.0

@export var grapplingHookScene : PackedScene
@export var grapplingHookSpeed = 400.0

@onready var character = $Character
@onready var _animation_player = $Character/AnimatedSprite2D
#@onready var _sprite_ship = $Character/ShipSprite
@onready var _projectile_spawn_point = $Character/GunSprite/ProjectileSpawnPoint
@onready var _sprite_gun = $Character/GunSprite
@onready var _arrow = $Character/Line2D

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")

var _hook : Node2D

signal projectile_shot(position, direction, speed)
signal grapplinghook_shot(position, direction, speed)
signal grapplinghook_detach()

const SPEED = 300.0
const ACCELERATE = 1200.0
const DECELERATE = 800.0
const HOOK_THRESHOLD = 0.5
const SHOOT_THRESHOLD = 0.5
const ROTATE_SPEED = 6.28
const TERMINAL_VELOCITY = 1200.0

func _physics_process(delta: float) -> void:
	# TODO? Could introduce some kind of free movement, but for now I'm relying on just grappling hook.
	#if moveInput.is_pressed and character.is_on_floor():
		#character.velocity.x = move_toward(character.velocity.x, moveInput.joystick_position.x * SPEED, ACCELERATE * delta)
	
	if character.velocity.x < 0:
		_animation_player.flip_h = true
	else:
		_animation_player.flip_h = false
	if character.is_on_floor():
		character.velocity.x = move_toward(character.velocity.x, 0, DECELERATE * delta)

	if _hook and _hook.is_hooked:
		#hacky magnitude
		var direction = (_hook.global_position - character.global_position).normalized()
		var magnitude = minf((_hook.global_position - character.global_position).length() * 5, 5000)
		character.velocity = character.velocity.move_toward(direction * TERMINAL_VELOCITY * 2, magnitude * delta)

	character.velocity.y = minf(TERMINAL_VELOCITY, character.velocity.y + gravity * delta)

	character.move_and_slide()
	
func _process(_delta: float) -> void:
	if abs(character.velocity.x) > 0 and character.is_on_floor():
		_animation_player.play("walk")
	elif not character.is_on_floor():
		_animation_player.play("jump")
	else:
		_animation_player.play("stand")
	
	#_arrow.position = character.position
	if shootInput.is_just_released:
		var direction = shootInput.joystick_position
		if direction.length() > SHOOT_THRESHOLD:
			direction = direction.normalized()
			var projectile = projectileScene.instantiate()
			
			projectile.velocity = direction * projectileSpeed
			projectile.lifetime = 4.0
			
			get_parent().add_child(projectile)
			
			projectile.global_position = _projectile_spawn_point.global_position
			
			projectile_shot.emit(projectile.global_position, direction, projectileSpeed)
			
	if moveInput.is_just_released:
		on_hook_detached()
		
		var direction = moveInput.joystick_position
		if direction.length() > HOOK_THRESHOLD:
			direction = direction.normalized()
			var grapplingHook = grapplingHookScene.instantiate()
			
			grapplingHook.player = character
			grapplingHook.velocity = direction * grapplingHookSpeed + character.velocity
			
			get_parent().add_child(grapplingHook)
			
			grapplingHook.global_position = character.global_position
			
			_hook = grapplingHook
			_hook.hook_detached.connect(on_hook_detached)
			
			grapplinghook_shot.emit(_hook.global_position, direction, grapplingHookSpeed)
	
	if moveInput.is_pressed:
		var target_rotation = Vector2(0, -1).angle_to(moveInput.joystick_position)
		#var angle_diff = angle_difference(character.rotation, target_rotation)
		#character.rotation = move_toward(character.rotation, character.rotation + angle_diff, ROTATE_SPEED * delta)
		_arrow.rotation = target_rotation
	if shootInput.is_pressed and shootInput.joystick_position.length() > SHOOT_THRESHOLD:
		_sprite_gun.global_rotation = Vector2(0, -1).angle_to(shootInput.joystick_position)

func on_hook_detached():
	if _hook:
		_hook.queue_free()
		grapplinghook_detach.emit()
		_hook = null
