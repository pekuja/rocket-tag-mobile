extends Camera2D
class_name GameCamera

@export var local_player : LocalPlayer
@export var tileMap : TileMapLayer
@export var spectatorCamera : bool = false

const BASE_WIDTH = 3840.0
const BASE_HEIGHT = 2160.0

var _scale = 1.0
var _mapBounds : Rect2i
var _unzoomedViewportSize = Vector2i(BASE_WIDTH, BASE_HEIGHT)

const BORDER_SIZE = Vector2(216.0, 216.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
	_mapBounds = tileMap.get_used_rect()
	var pos : Vector2i = tileMap.map_to_local(_mapBounds.position) - tileMap.tile_set.tile_size * 0.5
	var end : Vector2i = tileMap.map_to_local(_mapBounds.end) - tileMap.tile_set.tile_size * 0.5
	_mapBounds.position = pos 
	_mapBounds.end = end

func _on_viewport_resize():
	var h_scale = get_viewport().size.x / BASE_WIDTH
	var v_scale = get_viewport().size.y / BASE_HEIGHT
	_scale = min(h_scale, v_scale)
	self.zoom = _scale * Vector2(1.0, 1.0)
	
	if h_scale < v_scale:
		_unzoomedViewportSize = Vector2i(int(BASE_WIDTH), int(v_scale / h_scale * BASE_HEIGHT))
	else:
		_unzoomedViewportSize = Vector2i(int(BASE_WIDTH * h_scale / v_scale), int(BASE_HEIGHT))

func _process(_delta):
	if spectatorCamera or (local_player and not local_player.character.is_alive()):
		var min_pos = Vector2(INF, INF)
		var max_pos = Vector2(-INF, -INF)
		
		var players = get_parent().players.values()
		
		var num_live_players = 0
		for player : CharacterBody2D in players:
			if player.is_alive():
				num_live_players += 1
				min_pos.x = min(min_pos.x, player.global_position.x)
				max_pos.x = max(max_pos.x, player.global_position.x)
				min_pos.y = min(min_pos.y, player.global_position.y)
				max_pos.y = max(max_pos.y, player.global_position.y)
					
		if num_live_players > 0:				
			min_pos -= BORDER_SIZE
			max_pos += BORDER_SIZE
			
			self.global_position = (min_pos + max_pos) / 2
			var new_zoom = 1.0
			if max_pos.x > min_pos.x:
				new_zoom = minf(new_zoom, BASE_WIDTH / (max_pos.x - min_pos.x))
			if max_pos.y > min_pos.y:
				new_zoom = minf(new_zoom, BASE_HEIGHT / (max_pos.y - min_pos.y))
				
			self.zoom = new_zoom * _scale * Vector2(1.0, 1.0)
	elif local_player:
		self.global_position = local_player.character.global_position
	
	var topLeft = _mapBounds.position + _unzoomedViewportSize / 2
	var bottomRight = _mapBounds.end - _unzoomedViewportSize / 2
	
	global_position = global_position.clamp(topLeft, bottomRight)
	
