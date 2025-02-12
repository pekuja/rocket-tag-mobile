extends Node

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
@export var grapplinghook_scene : PackedScene
@export var explosion_scene : PackedScene

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var camera = $Camera2D
@onready var spawnPoint = $SpawnPoint

const SERVER_IP_ADDRESS = "192.168.0.140"
const PORT = 28132
const MAX_CONNECTIONS = 32

var _client_scene : ClientNode
var _next_projectile_id = 0

var players = {}
var hooks = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene
	if OS.has_feature("server"):
		scene = ResourceLoader.load("res://scenes/Server.tscn")
		add_child(scene.instantiate())
		
		_peer.create_server(PORT, MAX_CONNECTIONS)
		
		multiplayer.multiplayer_peer = _peer
	else:
		scene = ResourceLoader.load("res://scenes/Client.tscn")
		
		_client_scene = scene.instantiate()	
		add_child(_client_scene)
		
		_client_scene.local_player.projectile_shot.connect(_on_projectile_shot)
		_client_scene.local_player.grapplinghook_shot.connect(_on_grapplinghook_shot)
		_client_scene.local_player.grapplinghook_detach.connect(_on_grapplinghook_detach)
		
		camera.local_player = _client_scene.local_player
		
		_peer.create_client(SERVER_IP_ADDRESS, PORT)
		multiplayer.multiplayer_peer = _peer
		
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _on_connected_to_server():
	print("Connected to server")
	
func _on_connection_failed():
	print("Failed to connect to server")
	
func _on_player_connected(id):
	print("Player ", id, " connected")
	if id == 1: # no player character for server
		return
	
	var instance = remote_player_scene.instantiate()
	add_child(instance)
	
	print("Creating remote player instance for id ", id)
	instance.id = id
	players[id] = instance
	
	instance.global_position = spawnPoint.global_position
	
func _on_player_disconnected(id):
	print("Player ", id, " disconnected")
	
	remove_child(players[id])
	players.erase(id)
	
	if hooks.has(id):
		remove_child(hooks[id])
		hooks.erase(id)
	
func is_multiplayer():
	return _peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED

func _process(_delta):
	if not (OS.has_feature("server") and is_multiplayer()):
		return
	
	for playerId in players:
		var playerCharacter = players[playerId]
		var hookState : GrapplingHook.State = GrapplingHook.State.Inactive
		var hookPosition = Vector2(0,0)
		var hookVelocity = Vector2(0,0)
		if playerCharacter.hook:
			hookState = playerCharacter.hook.state
			hookPosition = playerCharacter.hook.position
			hookVelocity = playerCharacter.hook.velocity
		sync_player_state.rpc(
			playerId, playerCharacter.global_position, playerCharacter.velocity,
			hookState, hookPosition, hookVelocity)

func _on_projectile_shot(position, direction, speed):
	if is_multiplayer():
		sync_projectile_shot.rpc(_next_projectile_id, position, direction, speed)
		_next_projectile_id += 1

func _on_grapplinghook_shot(position, direction, speed):
	if is_multiplayer():
		sync_grapplinghook_shot.rpc(position, direction, speed)
	
func _on_grapplinghook_detach():
	if is_multiplayer():
		sync_grapplinghook_detach.rpc()

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
	
	if OS.has_feature("server"):
		projectile.projectile_impact.connect(_on_projectile_impact)
		projectile.projectile_expired.connect(_on_projectile_expired)
		
	projectile.player.projectiles[projectile.id] = projectile
	
	add_child(projectile)
	
@rpc("authority", "call_local")
func sync_create_explosion(position):
	print("Create explosion")
	var explosion = explosion_scene.instantiate()
	explosion.global_position = position
	
	add_child(explosion)

@rpc("authority", "call_local")
func sync_remove_projectile(player_id, projectile_id):
	var player = get_player_character(player_id)
	if player.projectiles.has(projectile_id):
		var projectile = player.projectiles[projectile_id]
		remove_child(projectile)
		player.projectiles.erase(projectile_id)

func _on_projectile_impact(projectile):
	print("Projectile impact")
	sync_create_explosion.rpc(projectile.global_position)
	sync_remove_projectile.rpc(projectile.player.id, projectile.id)
	
func _on_projectile_expired(projectile):
	print("Projectile expired")
	sync_create_explosion.rpc(projectile.global_position)

func get_player_character(id):
	if id == multiplayer.get_unique_id():
		return _client_scene.local_player.character
	else:
		return players[id]

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

@rpc("any_peer", "call_remote")
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

@rpc("authority", "call_remote")
func sync_player_state(id, position : Vector2i, velocity : Vector2,
		hookState : GrapplingHook.State, hookPosition : Vector2i, hookVelocity : Vector2):
	var player = get_player_character(id)
	
	if player:
		player.global_position = position
		player.velocity = velocity
		
	if hookState == GrapplingHook.State.Inactive:
		detach_hook(id)
	else:
		var hook = create_hook(id)
		hook.global_position = hookPosition
		hook.velocity = hookVelocity
		hook.state = hookState
