extends CharacterBody3D

const ROCKET_SPEED = 1100 * Constants.HU_TO_M
const KNOCKBACK = 5

@export var splash_area: Area3D

func _ready() -> void:
	assert(splash_area != null)
	self.velocity = self.basis * Vector3.FORWARD * ROCKET_SPEED

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		queue_free()
		for body in splash_area.get_overlapping_bodies():
			if (body is Player):
				var player: Player = body
				# TODO: consider further refinements to match TF2
				# - At time of explosion, move the rocket 1 Hammer unit away
				#   from the colliding surface and 10 Hammer units down. Use
				#   this new position as the origin of the explosion
				# - Increase knockback force when crouching
				# - Increase knockback force when in the air
				# - Mimic TF2's damage/knockback falloff calculation
				# - Lower knockback force for enemies, 0 knockback for allies
				# https://www.reddit.com/r/truetf2/comments/ogqho6/comment/h4ls374/
				# http://archive.today/2026.03.13-054427/https://www.reddit.com/r/truetf2/comments/ogqho6/how_does_rocket_jumping_work_from_a_technical/h4ls374/ 
				var player_center := player.collision_shape.global_position 
				var knockback_direction := self.global_position.direction_to(player_center)
				var distance := self.global_position.distance_to(player_center)
				var splash_area_radius := splash_area.scale.x / 2.0
				player.velocity += KNOCKBACK * knockback_direction * (splash_area_radius - distance)
	elif self.global_position.distance_to(Vector3.ZERO) > 100:
		# Delete rocket if it gets too far away (prevent rockets fired into the
		# air from going forever)
		queue_free()
