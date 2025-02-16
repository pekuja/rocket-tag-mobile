extends Control

@export var server_scene : PackedScene
@export var client_scene : PackedScene

func _on_join_game_pressed() -> void:
	var scene = client_scene.instantiate()
	scene.name = "Sync"
	var root = get_tree().get_root()
	root.add_child(scene)
	hide()

func _on_host_game_pressed() -> void:
	var scene = server_scene.instantiate()
	scene.name = "Sync"
	var root = get_tree().get_root()
	root.add_child(scene)
	hide()
