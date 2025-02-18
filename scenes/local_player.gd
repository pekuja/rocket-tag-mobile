extends Node2D

class_name LocalPlayer

@export var moveInput : TouchJoystick
@export var shootInput : TouchJoystick

@export var projectileSpeed = 400.0
const PROJECTILE_LIFETIME = 1.0

@export var grapplingHookSpeed = 400.0

@onready var character = $Character
@onready var _projectile_spawn_point = $Character/GunSprite/ProjectileSpawnPoint
@onready var _sprite_gun = $Character/GunSprite
@onready var _arrow = $Character/Arrow
@onready var _aim_guide = $AimGuide

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")

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
	
func _process(_delta: float) -> void:	
	if not character.is_alive():
		return
		
	if shootInput.is_just_released:
		var direction = shootInput.joystick_position
		if direction.length() > SHOOT_THRESHOLD:
			direction = direction.normalized()
			projectile_shot.emit(_projectile_spawn_point.global_position, direction, projectileSpeed)
			
	if moveInput.is_just_released:		
		var direction = moveInput.joystick_position
		if direction.length() > HOOK_THRESHOLD:
			grapplinghook_shot.emit(character.global_position, direction, grapplingHookSpeed)
		else:
			grapplinghook_detach.emit()
	
	if moveInput.is_pressed:
		var target_rotation = Vector2(0, -1).angle_to(moveInput.joystick_position)
		_arrow.rotation = target_rotation
	if shootInput.is_pressed and shootInput.joystick_position.length() > SHOOT_THRESHOLD:
		_sprite_gun.global_rotation = Vector2(0, -1).angle_to(shootInput.joystick_position)
		
		_aim_guide.visible = true
		_aim_guide.points[0] = _projectile_spawn_point.global_position - global_position
		var projectile_range = projectileSpeed * PROJECTILE_LIFETIME
		var end_pos = _projectile_spawn_point.global_position + shootInput.joystick_position.normalized() * projectile_range
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(_projectile_spawn_point.global_position, end_pos)
		query.exclude = [character]
		var result = space_state.intersect_ray(query)
		
		if result:
			_aim_guide.points[1] = result.position - global_position
		else:
			_aim_guide.points[1] = end_pos - global_position
	else:
		_aim_guide.visible = false
