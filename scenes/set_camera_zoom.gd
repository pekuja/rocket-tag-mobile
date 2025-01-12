extends Camera2D

@export var local_player : LocalPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

func _on_viewport_resize():
	var h_scale = get_viewport().size.x / 3840.0
	var v_scale = get_viewport().size.y / 2160.0
	var _scale = min(h_scale, v_scale)
	self.zoom = Vector2(_scale, _scale)

func _process(delta):
	if OS.has_feature("server"):
		# do something. zoom out to show all players perhaps?
		pass
	elif local_player:
		self.position = local_player.character.global_position
