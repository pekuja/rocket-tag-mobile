extends Node

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
@export var grapplinghook_scene : PackedScene
@export var explosion_scene : PackedScene

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var spawn_point = $Level/SpawnPoint

const PORT = 28132
const MAX_CONNECTIONS = 32

var players = {}
var hooks = {}

func _ready() -> void:
	_peer.create_server(PORT, MAX_CONNECTIONS)
	
	multiplayer.multiplayer_peer = _peer
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _process(_delta) -> void:
	for playerId in players:
		var player_character = players[playerId]
		var hookState : GrapplingHook.State = GrapplingHook.State.Inactive
		var hookPosition = Vector2(0,0)
		var hookVelocity = Vector2(0,0)
		if player_character.hook:
			hookState = player_character.hook.state
			hookPosition = player_character.hook.position
			hookVelocity = player_character.hook.velocity
		sync_player_state.rpc(
			playerId, player_character.global_position, player_character.velocity,
			hookState, hookPosition, hookVelocity)
	
func _on_player_connected(id):
	print("Player ", id, " connected")
	if id == 1: # no player character for server
		return
	
	var instance = remote_player_scene.instantiate()
	add_child(instance)
	
	print("Creating remote player instance for id ", id)
	instance.id = id
	players[id] = instance
	
	instance.global_position = spawn_point.global_position
	
func _on_player_disconnected(id):
	print("Player ", id, " disconnected")
	
	remove_child(players[id])
	players.erase(id)
	
	if hooks.has(id):
		remove_child(hooks[id])
		hooks.erase(id)
	
func _on_projectile_impact(projectile):
	print("Projectile impact")
	sync_create_explosion.rpc(projectile.global_position)
	sync_remove_projectile.rpc(projectile.player.id, projectile.id)
	
func _on_projectile_expired(projectile):
	print("Projectile expired")
	sync_create_explosion.rpc(projectile.global_position)
	
func get_player_character(id):
	return players[id]
	
@rpc("authority", "call_remote")
func sync_player_state(id, position : Vector2i, velocity : Vector2,
		hookState : GrapplingHook.State, hookPosition : Vector2i, hookVelocity : Vector2):
	pass # This function is Here for the RPC signature
	
@rpc("any_peer", "call_local")
func sync_projectile_shot(projectile_id, position, direction, speed):
	var id = multiplayer.get_remote_sender_id()
	direction = direction.normalized()
	var projectile : Projectile = projectile_scene.instantiate()
	
	projectile.player = get_player_character(id)
	projectile.id = projectile_id
	projectile.global_position = position
	projectile.velocity = direction * speed
	projectile.lifetime = 1.0
	
	if is_multiplayer_authority():
		projectile.projectile_impact.connect(_on_projectile_impact)
		projectile.projectile_expired.connect(_on_projectile_expired)
		
	projectile.player.projectiles[projectile.id] = projectile
	
	add_child(projectile)

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
	if hooks.has(id):
		return hooks[id]
		
	var player = get_player_character(id)
	var hook = grapplinghook_scene.instantiate()
	
	hook.player = player
	player.hook = hook
	
	add_child(hook)
	
	hooks[id] = hook
	
	return hook
	
func detach_hook(id):
	var player = get_player_character(id)
	player.hook = null
		
	if hooks.has(id):
		hooks[id].queue_free()
		hooks.erase(id)

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
	var id = multiplayer.get_remote_sender_id()
	pong.rpc_id(id, Time.get_ticks_usec())
	
@rpc("any_peer", "call_remote")
func pong(game_time : int):
	pass # This function is here for the RPC signature
	
