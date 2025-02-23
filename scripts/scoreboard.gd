extends HFlowContainer

@export var player_score_display_scene : PackedScene

var player_score_displays : Array[PlayerScoreDisplay]

func set_num_of_players(num_of_players : int):
	while num_of_players > player_score_displays.size():
		var new_display : PlayerScoreDisplay = player_score_display_scene.instantiate()
		add_child(new_display)
		new_display.score = 0
		new_display.update_score_display()
		player_score_displays.append(new_display)
	
	while num_of_players < player_score_displays.size():
		remove_child(player_score_displays.pop_back())
		
func update_score_display(player_index : int, color : int, score : int):
	if player_index < player_score_displays.size():
		var display : PlayerScoreDisplay = player_score_displays[player_index]
		display.player_color = color
		display.score = score
		display.update_score_display()
