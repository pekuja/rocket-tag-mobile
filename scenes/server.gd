extends Node

#@onready var _peer = ENetMultiplayerPeer.new()
#
#const PORT = 28132
#const MAX_CONNECTIONS = 32
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#_peer.create_server(PORT, MAX_CONNECTIONS)
	#multiplayer.multiplayer_peer = _peer
	#
	#multiplayer.peer_connected.connect(_on_player_connected)
	#multiplayer.peer_disconnected.connect(_on_player_disconnected)
	#
#func _on_player_connected(id):
	#print("Player ", id, " connected")
	#
	#print_once_per_client.rpc()
	#
#func _on_player_disconnected(id):
	#print("Player ", id, " disconnected")
#
#@rpc
#func print_once_per_client():
	#print("Print this once per client")
