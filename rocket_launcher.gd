extends Weapon

@export var root: Node3D
@export var player: CharacterBody3D
## Projectile origin
@export var head: Node3D
@export var rocket_scene := preload("rocket.tscn")

func get_attack_interval() -> float:
	return 800

func fire() -> void:
	print("firing rocket")
	var rocket: CharacterBody3D = rocket_scene.instantiate()
	rocket.position = head.global_position 
	rocket.basis = head.global_basis
	# Rocket can't hit the player who fired it (otherwise this could happen
	# when the player is walking forward while firing)
	rocket.add_collision_exception_with(player)
	# Achieved with collision layers/masks instead
	#player.add_collision_exception_with(rocket)
	root.add_child(rocket)
