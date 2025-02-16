extends Sync

const MAX_CONNECTIONS = 32

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
	
func _on_projectile_impact(projectile):
	print("Projectile impact")
	sync_create_explosion.rpc(projectile.global_position)
	sync_remove_projectile.rpc(projectile.player.id, projectile.id)
	
func _on_projectile_expired(projectile):
	print("Projectile expired")
	sync_create_explosion.rpc(projectile.global_position)
	
@rpc("any_peer", "call_local")
func sync_projectile_shot(projectile_id, position, direction, speed):
	var projectile = create_projectile(projectile_id, position, direction, speed)
	
	projectile.projectile_impact.connect(_on_projectile_impact)
	projectile.projectile_expired.connect(_on_projectile_expired)

@rpc("any_peer", "call_remote")
func ping():
	var id = multiplayer.get_remote_sender_id()
	pong.rpc_id(id, Time.get_ticks_usec())
