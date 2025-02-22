extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("server"):
		var scene = ResourceLoader.load("res://scenes/Server.tscn")
		var server_scene = scene.instantiate()
		var root = get_tree().get_root()
		root.add_child.call_deferred(server_scene)
		server_scene.name = "Sync"
	else:
		var scene = ResourceLoader.load("res://scenes/main_menu.tscn")
		var client_scene = scene.instantiate()
		var root = get_tree().get_root()
		root.add_child.call_deferred(client_scene)
