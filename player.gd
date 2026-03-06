extends CharacterBody3D
class_name Player

@export_group("Nodes")
@export var head: Node3D

@export_group("Settings")
@export_range(0, 10, 0.01) var mouse_sensitivity: float = 1.0
@export var movement_type: MovementType = MovementType.CS

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
# 16 HU = 1 ft
# 1 ft = 0.3048 m
# x_m = x_hu / 16 * 0.3048 = x_hu * 0.01905
## Factor to convert Hammer units to meters
const HU_TO_M := 0.01905
# https://developer.valvesoftware.com/wiki/List_of_Counter-Strike_2_console_commands_and_variables
const JUMP_VELOCITY = 301.993 * HU_TO_M
## https://developer.valvesoftware.com/wiki/Sv_friction
const FRICTION := 5.2
enum MovementType { CS, QUAKE, TF2_SOLDIER }
## sv_stopspeed
const STOP_SPEEDS: Dictionary[MovementType, float] = {
	MovementType.CS: 80 * HU_TO_M,
	MovementType.QUAKE: 100 * HU_TO_M,
	MovementType.TF2_SOLDIER: 100 * HU_TO_M,
}
var STOP_SPEED := STOP_SPEEDS[movement_type]
const MAX_GROUND_SPEEDS: Dictionary[MovementType, float] = {
	# https://counterstrike.fandom.com/wiki/Movement#Speed
	MovementType.CS: 250 * HU_TO_M,
	MovementType.QUAKE: 320 * HU_TO_M,
	# https://wiki.teamfortress.com/wiki/Classes#Speed
	MovementType.TF2_SOLDIER: 240 * HU_TO_M,
}
var MAX_GROUND_SPEED := MAX_GROUND_SPEEDS[movement_type]
const MAX_AIR_SPEED := 30 * HU_TO_M
## Accelerate from zero to max speed in 0.1 s
var MAX_ACCEL := MAX_GROUND_SPEED * 10

func _ready() -> void:
	assert(head != null, "ERROR: `head` not assigned a node value.");
	Input.set_use_accumulated_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func reset_movement_parameters() -> void:
	STOP_SPEED = STOP_SPEEDS[movement_type]
	MAX_GROUND_SPEED = MAX_GROUND_SPEEDS[movement_type]
	MAX_ACCEL = MAX_GROUND_SPEED * 10


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_look(event as InputEventMouseMotion)
	#match Input.mouse_mode:
		#Input.MOUSE_MODE_CAPTURED:
			#match event:
				#var mm when event is InputEventMouseMotion:
					#aim_look(mm as InputEventMouseMotion)
						
# Handles aim look with the mouse.
# Based on https://yosoyfreeman.github.io/article/godot/tutorial/achieving-better-mouse-input-in-godot-4-the-perfect-camera-controller
func aim_look(event: InputEventMouseMotion)-> void:
	var viewport_transform := get_tree().root.get_final_transform()
	var motion := (event.xformed_by(viewport_transform) as InputEventMouseMotion).relative

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
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Apply friction
		# TODO account for moving platform
		var speed := velocity.length()
		if speed > 0:
			# Deceleration due to friction is proportional to the current speed,
			# but when speed is smaller than STOP_SPEED, don't make the force of
			# friction any smaller to avoid a really slow sliding stop. This is
			# similar to static friction in real life.
			var friction_deceleration: float = max(speed, STOP_SPEED) * FRICTION
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
	
	#if Input.is_action_just_pressed("crouch"):
		
