extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

func _on_viewport_resize():
	var h_scale = get_viewport().size.x / 1920.0
	var v_scale = get_viewport().size.y / 1080.0
	var _scale = min(h_scale, v_scale)
	self.zoom = Vector2(_scale, _scale)
