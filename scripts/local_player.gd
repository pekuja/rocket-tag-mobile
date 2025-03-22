extends Node2D

class_name LocalPlayer

@onready var character : PlayerCharacter = $Character
@onready var _projectile_spawn_point = $Character/GunSprite/ProjectileSpawnPoint
@onready var _sprite_gun = $Character/GunSprite
@onready var _arrow = $Character/Arrow
@onready var _aim_guide = $AimGuide

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")

signal projectile_shot(target_position)
signal grapplinghook_shot(target_pos)
signal grapplinghook_detach()

const ACCELERATE = 1200.0
const DECELERATE = 800.0
const HOOK_THRESHOLD = 0.5
const SHOOT_THRESHOLD = 0.5
const ROTATE_SPEED = 6.28
const TERMINAL_VELOCITY = 1200.0

func _get_movement_input():
	return Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")
	
func _get_shoot_input():
	return Input.get_vector("Shoot_Left", "Shoot_Right", "Shoot_Up", "Shoot_Down")

func _get_projectile_target_pos():
	var projectile_range = Projectile.PROJECTILE_SPEED * Projectile.PROJECTILE_LIFETIME
	var end_pos = _projectile_spawn_point.global_position + _get_shoot_input().normalized() * projectile_range
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(_projectile_spawn_point.global_position, end_pos)
	query.exclude = [character]
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	else:
		return end_pos
		
func _get_hook_target_pos():
	var hook_range = GrapplingHook.MAXIMUM_LENGTH
	var end_pos = character.global_position + _get_movement_input().normalized() * hook_range
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(character.global_position, end_pos)
	query.collision_mask = GrapplingHook.COLLISION_MASK
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	else:
		return end_pos
		
func _ready() -> void:
	character.health = 0
	
func _process(_delta: float) -> void:	
	if not character.is_alive():
		return
		
	if Input.is_action_just_released("Shoot_Activate"):
		var direction = _get_shoot_input()
		if direction.length() > SHOOT_THRESHOLD:
			var target_pos = _get_projectile_target_pos()
			
			projectile_shot.emit(_get_projectile_target_pos())
	
	if Input.is_action_just_released("Move_Activate"):
		var direction = _get_movement_input()
		if direction.length() > HOOK_THRESHOLD:
			var target_pos = _get_hook_target_pos()
			grapplinghook_shot.emit(target_pos)
		else:
			grapplinghook_detach.emit()
	
	if Input.is_action_pressed("Move_Activate"):
		var target_rotation = Vector2(0, -1).angle_to(_get_movement_input())
		_arrow.rotation = target_rotation
	if Input.is_action_pressed("Shoot_Activate") and _get_shoot_input().length() > SHOOT_THRESHOLD:
		_sprite_gun.global_rotation = Vector2(0, -1).angle_to(_get_shoot_input())
		
		_aim_guide.visible = true
		_aim_guide.points[0] = _projectile_spawn_point.global_position - global_position
		_aim_guide.points[1] = _get_projectile_target_pos() - global_position
	else:
		_aim_guide.visible = false
