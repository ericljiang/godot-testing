@abstract class_name Weapon extends Node3D

var last_fire_time: float

## Delay between shots
@abstract func get_attack_interval() -> float
@abstract func fire() -> void

func _ready() -> void:
	# Ensure weapon is immediately ready to fire
	last_fire_time = Time.get_ticks_msec() - get_attack_interval()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_weapon"):
		var now := Time.get_ticks_msec()
		if (now < last_fire_time + get_attack_interval()):
			print("too soon to fire again")
			return
		fire()
		last_fire_time = now
