extends Control

class_name TouchJoystick

@onready var joystick_sprite = $Background/Joystick
@onready var background_sprite = $Background

@export var inputMap_left : StringName
@export var inputMap_right : StringName
@export var inputMap_up : StringName
@export var inputMap_down : StringName
@export var inputMap_activate : StringName

var joystick_position = Vector2(0,0)
var is_just_pressed = false
var is_pressed = false
var is_just_released = false

var _was_pressed = false

var touch_radius = 512
var dragging_index = -1
var mouse_is_dragging = false
var dragging_start = Vector2(0,0)

var joystick_movement_range = 64

func generate_axis_events(x : float, y : float):
	var left_event = InputEventAction.new()
	left_event.action = inputMap_left
	left_event.pressed = true
	left_event.strength = clampf(-x, 0.0, 1.0)
	Input.parse_input_event(left_event)
	
	var right_event = InputEventAction.new()
	right_event.action = inputMap_right
	right_event.pressed = true
	right_event.strength = clampf(x, 0.0, 1.0)
	Input.parse_input_event(right_event)
	
	var up_event = InputEventAction.new()
	up_event.action = inputMap_up
	up_event.pressed = true
	up_event.strength = clampf(-y, 0.0, 1.0)
	Input.parse_input_event(up_event)
	
	var down_event = InputEventAction.new()
	down_event.action = inputMap_down
	down_event.pressed = true
	down_event.strength = clampf(y, 0.0, 1.0)
	Input.parse_input_event(down_event)

func _input(event):
	if (event is InputEventScreenTouch) or \
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if (dragging_index < 0 and not mouse_is_dragging) and event.pressed:
			if (event.position - self.position).length() < touch_radius:
				if event is InputEventMouseButton:
					mouse_is_dragging = true
				else:
					dragging_index = event.index
				is_pressed = true
				joystick_position = Vector2(0,0)
				dragging_start = event.position
				background_sprite.global_position = event.position - background_sprite.size/2
				
				var action_event = InputEventAction.new()
				action_event.action = inputMap_activate
				action_event.pressed = true
				Input.parse_input_event(action_event)
				
				generate_axis_events(0.0, 0.0)
		elif not event.pressed:
			if (event is InputEventScreenTouch and dragging_index == event.index) or \
				(event is InputEventMouseButton and mouse_is_dragging):
				dragging_index = -1
				mouse_is_dragging = false
				is_pressed = false
				background_sprite.position = Vector2(0,0) - background_sprite.size/2
				
				var action_event = InputEventAction.new()
				action_event.action = inputMap_activate
				action_event.pressed = false
				Input.parse_input_event(action_event)
	elif (event is InputEventMouseMotion and mouse_is_dragging) or \
		(event is InputEventScreenDrag and dragging_index == event.index):
		joystick_position = (event.position - dragging_start) / joystick_movement_range
		
		generate_axis_events(joystick_position.x, joystick_position.y)
		
	
	if joystick_position.length() > 1:
		joystick_position = joystick_position / joystick_position.length()
	
	if is_pressed:
		joystick_sprite.position = joystick_position * joystick_movement_range + background_sprite.size/2 - joystick_sprite.size/2
	else:
		joystick_sprite.position = background_sprite.size/2 - joystick_sprite.size/2
	#joystick_position.y = -joystick_position.y # Flip so up is positive

func _process(_delta):	
	is_just_pressed = (is_pressed and not _was_pressed)
	is_just_released = (not is_pressed and _was_pressed)
	
	_was_pressed = is_pressed
