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
		elif not event.pressed:
			if (event is InputEventScreenTouch and dragging_index == event.index) or \
				(event is InputEventMouseButton and mouse_is_dragging):
				dragging_index = -1
				mouse_is_dragging = false
				is_pressed = false
				background_sprite.position = Vector2(0,0) - background_sprite.size/2
	elif (event is InputEventMouseMotion and mouse_is_dragging) or \
		(event is InputEventScreenDrag and dragging_index == event.index):
		joystick_position = (event.position - dragging_start) / joystick_movement_range
	
	if joystick_position.length() > 1:
		joystick_position = joystick_position / joystick_position.length()
	
	if is_pressed:
		joystick_sprite.position = joystick_position * joystick_movement_range + background_sprite.size/2 - joystick_sprite.size/2
	else:
		joystick_sprite.position = background_sprite.size/2 - joystick_sprite.size/2
	#joystick_position.y = -joystick_position.y # Flip so up is positive

func _process(_delta):
	if Input.is_action_just_pressed(inputMap_activate) or Input.is_action_just_released(inputMap_activate):
		is_pressed = Input.is_action_pressed(inputMap_activate)
		
	if Input.is_action_pressed(inputMap_activate):
		joystick_position = Input.get_vector(inputMap_left, inputMap_right, inputMap_up, inputMap_down)
	
	is_just_pressed = (is_pressed and not _was_pressed)
	is_just_released = (not is_pressed and _was_pressed)
	
	_was_pressed = is_pressed
