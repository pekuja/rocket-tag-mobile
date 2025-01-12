extends Control

var touch_radius = 256

var pressed_index = -1
var mouse_is_pressed = false

@export var is_pressed = false
@export var is_just_pressed = false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and not is_pressed:
			if (event.position - self.position).length() < touch_radius:
				pressed_index = event.index
		elif not event.pressed and is_pressed:
			if pressed_index == event.index:
				pressed_index = -1
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if (event.position - self.position).length() < touch_radius:
				mouse_is_pressed = true
		elif not event.pressed:
			mouse_is_pressed = false

func _process(delta):
	var old_is_pressed = is_pressed
	is_pressed = mouse_is_pressed or pressed_index >= 0
	
	is_just_pressed = is_pressed and not old_is_pressed
