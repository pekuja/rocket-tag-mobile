extends Sync

class_name ClientNode

@onready var camera = $Camera2D
@onready var local_player = $LocalPlayer
@onready var ping_label = $CanvasLayer/Ping

const SERVER_IP_ADDRESS = "192.168.0.140"
const PING_INTERVAL_US = 100000
const PING_RESULTS_TO_AVERAGE = 10

var _next_projectile_id = 0
var _ping_send_time = 0
var _waiting_for_ping = false
var _ping_results = []
var _game_time_offsets = []

func _ready() -> void:
	local_player.projectile_shot.connect(_on_projectile_shot)
	local_player.grapplinghook_shot.connect(_on_grapplinghook_shot)
	local_player.grapplinghook_detach.connect(_on_grapplinghook_detach)
			
	camera.local_player = local_player
	
	_peer.create_client(SERVER_IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = _peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _process(_delta) -> void:
	if not _waiting_for_ping and Time.get_ticks_usec() - _ping_send_time >= PING_INTERVAL_US:
		send_ping_to_server()

func is_multiplayer():
	return _peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED

func get_player_character(id):
	if id == multiplayer.get_unique_id():
		return local_player.character
	else:
		return players[id]
	
func get_average_game_time_offset():
	if _game_time_offsets.is_empty():
		return 0
	var average_offset = 0
	for offset in _game_time_offsets:
		average_offset += offset
	return average_offset / _game_time_offsets.size()
	
func get_game_time():
	return Time.get_ticks_usec() + get_average_game_time_offset()
	
func get_game_time_sec():
	return get_game_time() / 1000000.0

func send_ping_to_server():
	if is_multiplayer():
		_ping_send_time = Time.get_ticks_usec()
		ping.rpc_id(0)
	
func _on_connected_to_server():
	print("Connected to server")
	
func _on_connection_failed():
	print("Failed to connect to server")

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
	
@rpc("any_peer", "call_remote")
func pong(game_time : int):
	var current_time = Time.get_ticks_usec()
	var elapsed_time = current_time - _ping_send_time
	
	# one way latency is half of the total elapsed time for a two-way pingpong
	_ping_results.append(elapsed_time / 2)
	if _ping_results.size() > PING_RESULTS_TO_AVERAGE:
		_ping_results.pop_front()
	
	var average_latency = 0
	for latency in _ping_results:
		average_latency += latency
	average_latency /= _ping_results.size()
	
	var new_time = game_time + elapsed_time / 2
	var new_offset = new_time - current_time
	var old_average = get_average_game_time_offset()	
	_game_time_offsets.append(new_offset)
	if _game_time_offsets.size() > PING_RESULTS_TO_AVERAGE:
		_game_time_offsets.pop_front()
	var diff = get_average_game_time_offset() - old_average
	print("Adjusted time offset by %s ms" % (diff / 1000.0))
	
	ping_label.text = "Ping: %s ms " % (average_latency / 1000.0)
