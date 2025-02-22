extends Node
class_name Sync

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
@export var grapplinghook_scene : PackedScene
@export var explosion_scene : PackedScene

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var spawn_points_parent = $Level/SpawnPoints

const PORT = 28132

var players = {}
var player_ids : Array[int]

func get_random_spawn_point() -> Vector2i:
	var spawn_points = spawn_points_parent.get_children()
	if not spawn_points.is_empty():
		var spawn_point_index = randi_range(0, spawn_points.size() - 1)
		return spawn_points[spawn_point_index].global_position
	
	return Vector2i(0,0)
	
func _on_player_connected(id : int):
	print("Player ", id, " connected")
	
func _on_player_disconnected(id : int):
	print("Player ", id, " disconnected")
	
	var player = get_player_character(id)
	
	if player:
		detach_hook(id)
		
		remove_child(players[id])
		players.erase(id)
		player_ids.erase(id)
	
func _on_player_died(victim, killer):
	if victim == killer:
		killer.score -= 1
	else:
		killer.score += 1

func get_player_character(id : int):
	if players.has(id):
		return players[id]
	return null
	
func create_player(id):
	if get_player_character(id):
		return
	
	var instance : PlayerCharacter = remote_player_scene.instantiate()
	add_child(instance)
	
	print("Creating remote player instance for id ", id)
	instance.id = id
	players[id] = instance
	instance.update_sprite()
	
	if is_multiplayer_authority():
		instance.global_position = get_random_spawn_point()
		instance.player_died.connect(_on_player_died)
	
@rpc("any_peer", "call_remote")
func player_join_game():
	var id = multiplayer.get_remote_sender_id()
	print("Player %s joined game" % id)
	create_player(id)
	
	player_ids.append(id)
		
@rpc("authority", "call_remote")
func sync_player_list(new_player_ids : Array[int]):
	pass
	
@rpc("authority", "call_remote")
func sync_player_state(id : int, health : int, score : int, position : Vector2i, velocity : Vector2,
		hookState : GrapplingHook.State, hookPosition : Vector2i, hookVelocity : Vector2):
	pass # This function is Here for the RPC signature
	
func create_projectile(projectile_id, position, direction, speed):
	var id = multiplayer.get_remote_sender_id()
	var player = get_player_character(id)
	
	if not player.is_alive():
		return null
	
	var projectile : Projectile = projectile_scene.instantiate()
	projectile.init(player, projectile_id, position, direction, speed, 1.0)
	
	add_child(projectile)
	
	return projectile
	
@rpc("any_peer", "call_local")
func sync_projectile_shot(projectile_id, position, direction, speed):		
	create_projectile(projectile_id, position, direction, speed)

@rpc("authority", "call_local")
func sync_remove_projectile(player_id : int, projectile_id : int):
	var player = get_player_character(player_id)
	if player.projectiles.has(projectile_id):
		var projectile = player.projectiles[projectile_id]
		remove_child(projectile)
		player.projectiles.erase(projectile_id)
		
@rpc("authority", "call_local")
func sync_create_explosion(player_id : int, position):
	print("Create explosion")
	var explosion : Explosion = explosion_scene.instantiate()
	explosion.global_position = position
	explosion.player = get_player_character(player_id)
	
	add_child(explosion)

func create_hook(id : int):
	var player = get_player_character(id)
	var hook = GrapplingHook.get_hook(player)
	if hook:
		return hook
		
	hook = grapplinghook_scene.instantiate()
	
	hook.init(player)
	
	add_child(hook)
	
	return hook
	
func detach_hook(id : int):
	var player = get_player_character(id)
	if player:
		GrapplingHook.detach_hook(player)

@rpc("any_peer", "call_local")
func sync_grapplinghook_shot(position : Vector2i, direction : Vector2, speed : float):
	var id = multiplayer.get_remote_sender_id()
	var player = get_player_character(id)
	
	if not player.is_alive():
		return
	
	direction = direction.normalized()
	var hook = create_hook(id)
	
	hook.state = GrapplingHook.State.Flying
	
	hook.global_position = position
	hook.velocity = direction * speed

@rpc("any_peer", "call_remote")
func sync_grapplinghook_detach():
	var id = multiplayer.get_remote_sender_id()
	detach_hook(id)

@rpc("any_peer", "call_remote")
func ping():
	pass # This function is here for the RPC signature
	
@rpc("any_peer", "call_remote")
func pong(game_time : int):
	pass # This function is here for the RPC signature
	
