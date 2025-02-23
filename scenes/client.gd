extends Sync

class_name ClientNode

@onready var camera : GameCamera = $Camera2D
@onready var local_player : LocalPlayer = $LocalPlayer
@onready var ping_label = $CanvasLayer/Ping
@onready var scoreboard = $CanvasLayer/Scoreboard
@onready var canvas_layer = $CanvasLayer
@onready var joystick_left = $"CanvasLayer/Touch Joystick (Movement)"
@onready var joystick_right = $"CanvasLayer/Touch Joystick (Shooting)"

const PING_INTERVAL_US = 100000
const PING_RESULTS_TO_AVERAGE = 10

const STATE_SYNC_INTERVAL_US = 100000

const MAX_CONNECTIONS = 32
const TIME_TO_RESPAWN = 5.0

@export var server_address = "127.0.0.1"

var is_host = false

var _next_projectile_id = 0
var _ping_send_time = 0
var _waiting_for_ping = false
var _ping_results = []
var _game_time_offsets = []
var _last_state_sync_time = 0

func _ready() -> void:
	if is_host:
		_peer.create_server(PORT, MAX_CONNECTIONS)
		multiplayer.multiplayer_peer = _peer
		
		canvas_layer.remove_child(ping_label)
		
		if OS.has_feature("server"):
			# Dedicated server. Get rid of local player and some UI.
			remove_child(local_player)
			canvas_layer.remove_child(joystick_left)
			canvas_layer.remove_child(joystick_right)
			camera.spectatorCamera = true
		else:
			var id = multiplayer.get_unique_id()
			
			players[id] = local_player.character
			local_player.character.id = id
			local_player.character.update_sprite()
			local_player.character.global_position = get_random_spawn_point()
			local_player.character.player_died.connect(_on_player_died)
			
			player_ids.append(id)
			
			scoreboard.set_num_of_players(1)
			scoreboard.update_score_display(0, local_player.character.sprite_frame_index, 0)
	else:
		print("Connecting to server at ", server_address)
		
		_peer.create_client(server_address, PORT)
		multiplayer.multiplayer_peer = _peer
		
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
	
	if not OS.has_feature("server"):
		local_player.projectile_shot.connect(_on_projectile_shot)
		local_player.grapplinghook_shot.connect(_on_grapplinghook_shot)
		local_player.grapplinghook_detach.connect(_on_grapplinghook_detach)
			
		camera.local_player = local_player
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _process(delta) -> void:
	if is_multiplayer_authority():
		var game_time = Time.get_ticks_usec()
		
		var send_state_sync = false
		
		if game_time - _last_state_sync_time >= STATE_SYNC_INTERVAL_US:
			send_state_sync = true
			_last_state_sync_time = game_time
		
		for playerId in players:
			var player_character = players[playerId]
			var hookState : GrapplingHook.State = GrapplingHook.State.Inactive
			var hookPosition = Vector2(0,0)
			var hookVelocity = Vector2(0,0)
			if player_character.hook:
				hookState = player_character.hook.state
				hookPosition = player_character.hook.position
				hookVelocity = player_character.hook.velocity
			
			var health_update_needed = false
			if player_character.health == 0:
				if player_character.respawn_timer <= 0:
					health_update_needed = true
					player_character.respawn_timer = TIME_TO_RESPAWN
				else:
					player_character.respawn_timer -= delta
					
					if player_character.respawn_timer <= 0:
						health_update_needed = true
						player_character.health = 100
						player_character.update_healthbar()
						player_character.global_position = get_random_spawn_point()
						player_character.velocity = Vector2(0.0, 0.0)
			
			if send_state_sync or health_update_needed:
				sync_player_state.rpc(
					game_time, playerId, player_character.health, player_character.score,
					player_character.global_position, player_character.velocity,
					hookState, hookPosition, hookVelocity)
	else:
		if not _waiting_for_ping and Time.get_ticks_usec() - _ping_send_time >= PING_INTERVAL_US:
			send_ping_to_server()
	
func _on_player_disconnected(id : int):
	super(id)
	
	scoreboard.set_num_of_players(players.size())

func is_multiplayer():
	return _peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED
	
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
		_waiting_for_ping = true
		_ping_send_time = Time.get_ticks_usec()
		ping.rpc_id(1)
	
func _on_connected_to_server():
	print("Connected to server")
	
	var id = multiplayer.get_unique_id()
	local_player.character.id = id
	local_player.character.update_sprite()
	
	player_join_game.rpc_id(1)

@rpc("authority", "call_remote", "reliable")
func sync_player_list(new_player_ids : Array[int]):	
	print("Player list synced: ", new_player_ids)
	player_ids = new_player_ids
	for player_id in player_ids:
		if player_id == multiplayer.get_unique_id():
			players[player_id] = local_player.character
		else:
			create_player(player_id)
	print("Done creating player characters")
	
	scoreboard.set_num_of_players(players.size())
	
func _on_connection_failed():
	print("Failed to connect to server")

func _on_projectile_shot(target_position):
	if is_multiplayer():
		sync_projectile_shot.rpc(_next_projectile_id, target_position)
		_next_projectile_id += 1
		

func _on_projectile_impact(projectile):
	print("Projectile impact")
	sync_create_explosion.rpc(projectile.player.id, projectile.global_position)
	sync_remove_projectile.rpc(projectile.player.id, projectile.id)
	
func _on_projectile_expired(projectile):
	print("Projectile expired")
	sync_create_explosion.rpc(projectile.player.id, projectile.global_position)

func _on_grapplinghook_shot(target_pos):
	if is_multiplayer():
		sync_grapplinghook_shot.rpc(target_pos)
	
func _on_grapplinghook_detach():
	if is_multiplayer():
		sync_grapplinghook_detach.rpc()

func _on_player_died(victim, killer):
	if victim == killer:
		killer.score -= 1
	else:
		killer.score += 1
	
	print("Updating player score for ", killer.id, ": ", killer.score)
	scoreboard.update_score_display(get_player_index(killer.id), killer.sprite_frame_index, killer.score)
		
func get_player_index(player_id : int):
	return player_ids.find(player_id)

@rpc("authority", "call_remote", "unreliable_ordered")
func sync_player_state(game_time : int, id : int, health : int, score : int, 
		position : Vector2i, velocity : Vector2,
		hookState : GrapplingHook.State, hookPosition : Vector2i, hookVelocity : Vector2):
	var player = get_player_character(id)
	
	if player:
		player.global_position = position
		player.velocity = velocity
		player.health = health
		player.update_healthbar()
		player.score = score
				
		scoreboard.update_score_display(get_player_index(id), player.sprite_frame_index, score)
		
		if hookState == GrapplingHook.State.Inactive:
			detach_hook(id)
		else:
			var hook = create_hook(id)
			hook.global_position = hookPosition
			hook.velocity = hookVelocity
			hook.state = hookState
		
		# Account for network latency
		var local_game_time = get_game_time()
		var total_delta = local_game_time - game_time
		if total_delta > 0:
			var single_delta = 1000000 / Engine.physics_ticks_per_second
			var delta_sec = single_delta / 1000000.0
			var frames = total_delta / single_delta
			if frames > 0:
				print("Catching up player simulation for ", frames, " frames")
				while frames > 0:
					frames -= 1
					player._physics_process(delta_sec)
					
					var hook = GrapplingHook.get_hook(player)
					if hook:
						hook._physics_process(delta_sec)

@rpc("any_peer", "call_remote", "reliable")
func player_join_game():
	super()
	
	if is_multiplayer_authority():
		sync_player_list.rpc(player_ids)
		
		scoreboard.set_num_of_players(player_ids.size())
		
		var id = multiplayer.get_remote_sender_id()
		var player = get_player_character(id)
		scoreboard.update_score_display(get_player_index(id), player.sprite_frame_index, 0)

@rpc("any_peer", "call_local", "reliable")
func sync_projectile_shot(projectile_id, target_position):
	if is_multiplayer_authority():
		var projectile = create_projectile(projectile_id, target_position)
		
		if projectile:
			projectile.projectile_impact.connect(_on_projectile_impact)
			projectile.projectile_expired.connect(_on_projectile_expired)
	else:
		create_projectile(projectile_id, target_position)

@rpc("any_peer", "call_remote", "reliable")
func ping():
	var id = multiplayer.get_remote_sender_id()
	pong.rpc_id(id, Time.get_ticks_usec())

@rpc("any_peer", "call_remote", "reliable")
func pong(game_time : int):
	_waiting_for_ping = false
	
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
	#print("Adjusted time offset by %s ms" % (diff / 1000.0))
	
	ping_label.text = "Ping: %s ms " % (average_latency / 1000.0)
