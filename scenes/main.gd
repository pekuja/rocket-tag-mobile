extends Node

@export var remote_player_scene : PackedScene
@export var projectile_scene: PackedScene
# @export var cert : X509Certificate

@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
# @onready var _peer : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()

const SERVER_IP_ADDRESS = "192.168.0.139"
const PORT = 28132
const MAX_CONNECTIONS = 32

var _client_scene : ClientNode

var _players = {}

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
	_players[id] = instance
	
func _on_player_disconnected(id):
	print("Player ", id, " disconnected")
	
	remove_child(_players[id])
	_players[id] = null

func _process(_delta):
	if OS.has_feature("server"):
		return
	
	sync_player_position.rpc(_client_scene.local_player.character.global_position, _client_scene.local_player.character.rotation)

func _on_projectile_shot(position, direction):
	sync_projectile_shot.rpc(position, direction)

@rpc("any_peer")
func sync_projectile_shot(position, direction):
		direction = direction.normalized()
		var projectile = projectile_scene.instantiate()
		
		const projectileSpeed = 400.0
		
		projectile.velocity = direction * projectileSpeed
		projectile.lifetime = 1.0
		
		add_child(projectile)
		
		projectile.global_position = position
		

@rpc("any_peer")
func sync_player_position(position, rotation):
	
	var id = multiplayer.get_remote_sender_id()
	#print("syncing position for player ", id)
	
	if _players.has(id):
		_players[id].global_position = position
		_players[id].rotation = rotation
