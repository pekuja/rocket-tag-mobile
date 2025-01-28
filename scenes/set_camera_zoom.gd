extends Camera2D

@export var local_player : LocalPlayer
@export var tileMap : TileMapLayer

var _scale = 1.0
var _mapBounds : Rect2i

const BASE_WIDTH = 3840.0
const BASE_HEIGHT = 2160.0

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

func _process(_delta):	
	if OS.has_feature("server"):
		var average_pos = Vector2(0,0)
		var min_pos = Vector2(INF, INF)
		var max_pos = Vector2(-INF, -INF)
		
		var players = get_parent().players.values()
		if not players.is_empty():
			for player : CharacterBody2D in players:
				average_pos += player.global_position
				min_pos.x = min(min_pos.x, player.global_position.x)
				max_pos.x = max(max_pos.x, player.global_position.x)
				min_pos.y = min(min_pos.y, player.global_position.y)
				max_pos.y = max(max_pos.y, player.global_position.y)
			
			average_pos /= players.size()
			
			min_pos -= BORDER_SIZE
			max_pos += BORDER_SIZE
			
			#print("average pos: ", average_pos)
			self.global_position = average_pos
			var new_zoom = 1.0
			if max_pos.x > min_pos.x:
				new_zoom = minf(new_zoom, BASE_WIDTH / (max_pos.x - min_pos.x))
			if max_pos.y > min_pos.y:
				new_zoom = minf(new_zoom, BASE_WIDTH / (max_pos.y - min_pos.y))
				
			self.zoom = new_zoom * _scale * Vector2(1.0, 1.0)
		#else:
			#print("no players :(")
	elif local_player:
		self.global_position = local_player.character.global_position
	
	self.global_position = \
		self.global_position.clamp(
			_mapBounds.position + Vector2i(self.zoom * Vector2(BASE_WIDTH, BASE_HEIGHT)),
			_mapBounds.end - Vector2i(self.zoom * Vector2(BASE_WIDTH, BASE_HEIGHT)))
