extends CharacterBody3D

const ROCKET_SPEED = 1100 * Constants.HU_TO_M

@export var splash_area: Area3D

func _ready() -> void:
	assert(splash_area != null)
	self.velocity = self.basis * Vector3.FORWARD * ROCKET_SPEED

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		print("I collided with ", collision.get_collider())
		for body in splash_area.get_overlapping_bodies():
			if (body is Player):
				var player: Player = body
				var rocket_to_player_vector := player.global_position - self.global_position
				var knockback_direction := rocket_to_player_vector.normalized()
				var distance := rocket_to_player_vector.length()
				player.velocity += 5 * knockback_direction / distance
		queue_free()
