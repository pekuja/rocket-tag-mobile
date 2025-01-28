extends CharacterBody2D

@onready var _animation_player = $AnimatedSprite2D

var hook : Node2D

const SPEED = 300.0
const ACCELERATE = 1200.0
const DECELERATE = 800.0
const HOOK_THRESHOLD = 0.5
const SHOOT_THRESHOLD = 0.5
const ROTATE_SPEED = 6.28
const TERMINAL_VELOCITY = 1200.0

var gravity: int = ProjectSettings.get("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# TODO? Could introduce some kind of free movement, but for now I'm relying on just grappling hook.
	#if moveInput.is_pressed and character.is_on_floor():
		#character.velocity.x = move_toward(character.velocity.x, moveInput.joystick_position.x * SPEED, ACCELERATE * delta)
	
	if velocity.x < 0:
		_animation_player.flip_h = true
	else:
		_animation_player.flip_h = false
		
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATE * delta)

	if hook and hook.is_hooked:
		#hacky magnitude
		var direction = (hook.global_position - global_position).normalized()
		var magnitude = minf((hook.global_position - global_position).length() * 5, 5000)
		velocity = velocity.move_toward(direction * TERMINAL_VELOCITY * 2, magnitude * delta)

	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

	move_and_slide()

func _process(delta: float) -> void:
	if abs(velocity.x) > 0 and is_on_floor():
		_animation_player.play("walk")
	elif not is_on_floor():
		_animation_player.play("jump")
	else:
		_animation_player.play("stand")
