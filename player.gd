extends CharacterBody3D

@export_group("Nodes")
@export var head: Node3D

@export_group("Settings")
@export_range(0, 10, 0.01) var mouse_sensitivity: float = 1.0

# Movement parameters
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Mouselook parameters
const MAX_PITCH = deg_to_rad(90)
const MIN_PITCH = -MAX_PITCH
# Attempt to replicate Source engine scaling. CS and TF2 use 0.022 as the
# default value for m_yaw and m_pitch.
# https://liquipedia.net/counterstrike/Mouse_Settings
# If the user's mouse is 1000 DPI, when moving the mouse 1 inch, the engine
# should report 1000 dots or counts, which should result in a rotation of 22
# degrees, multiplied by the sensitivity.
const DEGREES_PER_UNIT = 0.022
const RADS_PER_UNIT = deg_to_rad(DEGREES_PER_UNIT)

# Movement parameters
## 320 HU/s = 20 ft/s = 6.096 m/s
const MAX_GROUND_SPEED := 6.096
## 30 HU/s = 1.875 ft/s = 0.5715 m/s
const MAX_AIR_SPEED := 0.5715
## Accelerate from zero to max speed in 0.1 s
const MAX_ACCEL := MAX_GROUND_SPEED * 10

func _ready() -> void:
	Input.set_use_accumulated_input(false)
	if head == null:
		assert(head != null, "ERROR: `head` not assigned a node value.");

func _unhandled_input(event: InputEvent) -> void:
	match Input.mouse_mode:
		Input.MOUSE_MODE_VISIBLE:
			match event:
				var mb when event is InputEventMouseButton:
					var button_index := (mb as InputEventMouseButton).button_index
					print("Button: ", button_index)
					match button_index:
						1:
							Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				var k when event is InputEventKey:
					if (k as InputEventKey).is_action_pressed("ui_cancel"):
						get_tree().quit()
		Input.MOUSE_MODE_CAPTURED:
			match event:
				var mm when event is InputEventMouseMotion:
					aim_look(mm as InputEventMouseMotion)
				var k when event is InputEventKey:
					if (k as InputEventKey).is_action_pressed("ui_cancel"):
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
						
# Handles aim look with the mouse.
# Based on https://yosoyfreeman.github.io/article/godot/tutorial/achieving-better-mouse-input-in-godot-4-the-perfect-camera-controller
func aim_look(event: InputEventMouseMotion)-> void:
	var viewport_transform: Transform2D = get_tree().root.get_final_transform()
	var motion: Vector2 = (event.xformed_by(viewport_transform) as InputEventMouseMotion).relative

	motion *= RADS_PER_UNIT
	motion *= mouse_sensitivity

	add_yaw(motion.x)
	add_pitch(motion.y)

# Rotates the character around the local Y-axis by a given amount (in radians)
# to achieve yaw.
func add_yaw(amount: float) -> void:
	if is_zero_approx(amount):
		return
	
	rotate_object_local(Vector3.DOWN, amount)
	orthonormalize()

# Rotates the head around the local X-axis by a given amount (in radians) to
# achieve pitch.
func add_pitch(amount: float) -> void:
	if is_zero_approx(amount):
		return

	head.rotate_object_local(Vector3.LEFT, amount)
	head.rotation.x = clamp(head.rotation.x, MIN_PITCH, MAX_PITCH)
	head.orthonormalize()

func _physics_process(delta: float) -> void:
	# Grounded movement
	# Based on https://www.youtube.com/watch?v=v3zT3Z5apaM
	if is_on_floor():
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Apply friction
		# TODO account for moving platform
		## https://developer.valvesoftware.com/wiki/Sv_friction
		const FRICTION := 5.2
		var speed := velocity.length()
		if speed > 0:
			var friction_deceleration: float = max(speed, 2) * FRICTION
			# Scale down the velocity by an amount that is equivalent to
			# subtracting the friction_deceleration applied over delta time.
			# I don't know why this ratio becomes > 1.
			## Fraction of current speed that should be removed due to friction
			var speed_reduction_fraction: float = clamp(friction_deceleration * delta / speed, 0, 1)
			velocity *= 1 - speed_reduction_fraction
		
		# Apply user input
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if !input_dir.is_zero_approx():
			# TODO remove normalization to handle analog inputs?
			## Normalized vector corresponding to current player inputs
			var wish_direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			## Current speed in the direction of wish_direction?
			var current_speed := velocity.dot(wish_direction)
			var add_speed: float = clamp(MAX_GROUND_SPEED - current_speed, 0, MAX_ACCEL * delta)
			velocity += add_speed * wish_direction

	# Air movement
	else:
		# Apply gravity
		velocity += get_gravity() * delta

		# Apply user input
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if !input_dir.is_zero_approx():
			# TODO remove normalization to handle analog inputs?
			## Normalized vector corresponding to current player inputs
			var wish_direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			## Current speed in the direction of wish_direction?
			var current_speed := velocity.dot(wish_direction)
			var add_speed: float = clamp(MAX_AIR_SPEED - current_speed, 0, MAX_ACCEL * delta)
			velocity += add_speed * wish_direction

	move_and_slide()
