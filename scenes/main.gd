extends Node

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
@export var grapplinghook_scene : PackedScene
# @export var cert : X509Certificate

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
# @onready var _peer : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()

@onready var camera = $Camera2D
@onready var spawnPoint = $SpawnPoint

const SERVER_IP_ADDRESS = "192.168.0.140"
const PORT = 28132
const MAX_CONNECTIONS = 32

var _client_scene : ClientNode

var players = {}
var hooks = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene
	if OS.has_feature("server"):
		scene = ResourceLoader.load("res://scenes/Server.tscn")
		add_child(scene.instantiate())
		
		# const KEY_FILE = "rocket.key"
		# const CERT_FILE = "rocket.crt"
		
		#var key : CryptoKey
		#
		#if not FileAccess.file_exists(KEY_FILE):
			#print("Generating crypto key in ", KEY_FILE, " and cert in ", CERT_FILE)
			#var crypto = Crypto.new()
			#key = crypto.generate_rsa(4096)
			#cert = crypto.generate_self_signed_certificate(key, "CN=pekuja.com,O=Pekka Kujansuu,C=FI")
			#key.save(KEY_FILE)
			#cert.save(CERT_FILE)
		#else:
			#key = CryptoKey.new()
			#key.load(KEY_FILE)
		
		_peer.create_server(PORT, MAX_CONNECTIONS)
		
		#_peer.create_server(PORT, "*", TLSOptions.server(key, cert))
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
		#_peer.create_client("wss://" + SERVER_IP_ADDRESS + ":" + str(PORT), TLSOptions.client(cert))
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
		sync_player_position.rpc(playerId, playerCharacter.global_position, playerCharacter.velocity)

func _on_projectile_shot(position, direction, speed):
	if is_multiplayer():
		sync_projectile_shot.rpc(position, direction, speed)

func _on_grapplinghook_shot(position, direction, speed):
	if is_multiplayer():
		sync_grapplinghook_shot.rpc(position, direction, speed)
	
func _on_grapplinghook_detach():
	if is_multiplayer():
		sync_grapplinghook_detach.rpc()

@rpc("any_peer", "call_remote")
func sync_projectile_shot(position, direction, speed):
	direction = direction.normalized()
	var projectile = projectile_scene.instantiate()
	
	projectile.global_position = position
	projectile.velocity = direction * speed
	projectile.lifetime = 1.0
	
	add_child(projectile)	

@rpc("any_peer", "call_remote")
func sync_grapplinghook_shot(position, direction, speed):
	direction = direction.normalized()
	var hook = grapplinghook_scene.instantiate()
	
	hook.global_position = position	
	hook.velocity = direction * speed
	var id = multiplayer.get_remote_sender_id()
	hook.player = players[id]
	players[id].hook = hook
	
	add_child(hook)
	
	if hooks.has(id):
		hooks[id].queue_free()
	
	hooks[id] = hook

@rpc("any_peer", "call_remote")
func sync_grapplinghook_detach():
	var id = multiplayer.get_remote_sender_id()
	
	if hooks.has(id):
		players[id].hook = null
		hooks[id].queue_free()
		hooks.erase(id)

@rpc("authority", "call_remote")
func sync_player_position(id, position, velocity):
	if players.has(id):
		players[id].global_position = position
		players[id].velocity = velocity
	elif id == multiplayer.get_unique_id():
		_client_scene.local_player.character.global_position = position
		_client_scene.local_player.character.velocity = velocity
