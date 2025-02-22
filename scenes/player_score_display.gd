extends HFlowContainer
class_name PlayerScoreDisplay

@export var player_portrait_images : Array[AtlasTexture]
@export var score : int
@export var player_color : int

@onready var portrait_texturerect = $"Player Portrait"
@onready var score_label = $"Player Score"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_score_display()
	
func update_score_display():
	if player_color >= 0 and player_color < player_portrait_images.size():
		portrait_texturerect.texture = player_portrait_images[player_color]
	elif not player_portrait_images.is_empty():
		print("No player color for index ", player_color)
		portrait_texturerect.texture = player_portrait_images[0]
		
	score_label.text = "%s" % score
