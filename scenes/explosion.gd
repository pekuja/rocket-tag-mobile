extends Node2D

@onready var _animatedSprite = $AnimatedSprite2D
@onready var _area = $Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_animatedSprite.play()
	_animatedSprite.animation_finished.connect(_on_animation_finished)

#func _physics_process(_delta):
	#for body in _area.get_overlapping_bodies():
	#	print("overlap body ", body)

func _on_animation_finished():
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("body entered ", body)
	#pass # Replace with function body.
	if body is PlayerCharacter:
		print("it's a player character")
		body.explosion_hit(global_position)
