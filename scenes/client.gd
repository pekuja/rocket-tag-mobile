extends Node

class_name ClientNode

@onready var local_player = $LocalPlayer
@onready var ping_label = $CanvasLayer/Ping

#@onready var _peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
#
#@onready var _player_character : Node2D = $"Player Character"
#
#const SERVER_IP_ADDRESS = "192.168.0.139"
#const PORT = 28132
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#_peer.create_client(SERVER_IP_ADDRESS, PORT)
	#multiplayer.multiplayer_peer = _peer
#
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
	#
#func _on_connected_to_server():
	#print("Connected to server")
	#print_once_per_client.rpc()
	#
#func _on_connection_failed():
	#print("Failed to connect to server")
	#
#
#@rpc
#func print_once_per_client():
	#print("Print this once per client")
