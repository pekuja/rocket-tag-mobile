extends Node
class_name Sync

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
@export var grapplinghook_scene : PackedScene
@export var explosion_scene : PackedScene

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var spawn_point = $Level/SpawnPoint

const PORT = 28132

var players = {}
	
func _on_player_connected(id):
	print("Player ", id, " connected")
	if id == 1: # no player character for server
		return
	
	var instance = remote_player_scene.instantiate()
	add_child(instance)
	
	print("Creating remote player instance for id ", id)
	instance.id = id
	players[id] = instance
	instance.update_sprite()
	
	instance.global_position = spawn_point.global_position
	
func _on_player_disconnected(id):
	print("Player ", id, " disconnected")
	
	detach_hook(id)
	
	remove_child(players[id])
	players.erase(id)

func get_player_character(id):
	return players[id]
	
@rpc("authority", "call_remote")
func sync_player_state(id, position : Vector2i, velocity : Vector2,
		hookState : GrapplingHook.State, hookPosition : Vector2i, hookVelocity : Vector2):
	pass # This function is Here for the RPC signature
	
func create_projectile(projectile_id, position, direction, speed):
	var id = multiplayer.get_remote_sender_id()
	var projectile : Projectile = projectile_scene.instantiate()
	projectile.init(get_player_character(id), projectile_id, position, direction, speed, 1.0)
	
	add_child(projectile)
	
	return projectile
	
@rpc("any_peer", "call_local")
func sync_projectile_shot(projectile_id, position, direction, speed):
	create_projectile(projectile_id, position, direction, speed)

@rpc("authority", "call_local")
func sync_remove_projectile(player_id, projectile_id):
	var player = get_player_character(player_id)
	if player.projectiles.has(projectile_id):
		var projectile = player.projectiles[projectile_id]
		remove_child(projectile)
		player.projectiles.erase(projectile_id)
		
@rpc("authority", "call_local")
func sync_create_explosion(position):
	print("Create explosion")
	var explosion = explosion_scene.instantiate()
	explosion.global_position = position
	
	add_child(explosion)

func create_hook(id):
	var player = get_player_character(id)
	var hook = GrapplingHook.get_hook(player)
	if hook:
		return hook
		
	hook = grapplinghook_scene.instantiate()
	
	hook.init(player)
	
	add_child(hook)
	
	return hook
	
func detach_hook(id):
	var player = get_player_character(id)
	GrapplingHook.detach_hook(player)

@rpc("any_peer", "call_local")
func sync_grapplinghook_shot(position : Vector2i, direction : Vector2, speed : float):
	direction = direction.normalized()
	var id = multiplayer.get_remote_sender_id()
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
	
