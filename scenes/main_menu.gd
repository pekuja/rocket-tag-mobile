extends Control

@export var main_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_join_game_pressed() -> void:
	var main = main_scene.instantiate()
	var root = get_tree().get_root()
	root.add_child(main)
	hide()

func _on_host_game_pressed() -> void:
	var main = main_scene.instantiate()
	var root = get_tree().get_root()
	root.add_child(main)
	hide()
