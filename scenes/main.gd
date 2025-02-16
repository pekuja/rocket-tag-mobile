extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("server"):
		var scene = ResourceLoader.load("res://scenes/Server.tscn")
		var server_scene = scene.instantiate()
		add_child(server_scene)
		server_scene.name = "Sync"
	else:
		var scene = ResourceLoader.load("res://scenes/Client.tscn")
		var client_scene = scene.instantiate()	
		add_child(client_scene)
		client_scene.name = "Sync"
