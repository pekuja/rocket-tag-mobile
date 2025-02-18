extends Node2D

@onready var _animatedSprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_animatedSprite.play()
	_animatedSprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		body.explosion_hit(global_position)
