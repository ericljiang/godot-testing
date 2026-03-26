extends CharacterBody3D

const ROCKET_SPEED = 1100 * Constants.HU_TO_M
const KNOCKBACK = 5

@export var splash_area: Area3D
@export var particle_system: GPUParticles3D
@export var mesh: MeshInstance3D

func _ready() -> void:
	assert(splash_area != null)
	assert(particle_system != null)
	assert(mesh != null)
	self.velocity = self.basis * Vector3.FORWARD * ROCKET_SPEED

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		delete_rocket()
		for body in splash_area.get_overlapping_bodies():
			if (body is Player):
				var player: Player = body
				# TODO: consider further refinements to match TF2
				# - At time of explosion, move the rocket 1 Hammer unit away
				#   from the colliding surface and 10 Hammer units down. Use
				#   this new position as the origin of the explosion (DONE)
				# - Increase knockback force when crouching
				# - Increase knockback force when in the air
				# - Mimic TF2's damage/knockback falloff calculation
				# - Lower knockback force for enemies, 0 knockback for allies
				# https://www.reddit.com/r/truetf2/comments/ogqho6/comment/h4ls374/
				# http://archive.today/2026.03.13-054427/https://www.reddit.com/r/truetf2/comments/ogqho6/how_does_rocket_jumping_work_from_a_technical/h4ls374/ 
				var knockback_center := self.global_position \
					+ collision.get_normal() * Constants.HU_TO_M \
					+ Vector3.DOWN * 10 * Constants.HU_TO_M
				var player_center := player.collision_shape.global_position
				var knockback_direction := knockback_center.direction_to(player_center)
				var distance := self.global_position.distance_to(player_center)
				var splash_area_radius := splash_area.scale.x / 2.0
				player.velocity += KNOCKBACK * knockback_direction * (splash_area_radius - distance)
	elif self.global_position.distance_to(Vector3.ZERO) > 100:
		# Delete rocket if it gets too far away (prevent rockets fired into the
		# air from going forever)
		delete_rocket()

func delete_rocket() -> void:
	mesh.hide()
	particle_system.amount_ratio = 0
	await get_tree().create_timer(particle_system.lifetime).timeout
	queue_free()
