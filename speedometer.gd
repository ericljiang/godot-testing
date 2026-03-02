extends Label

@export var player: Player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var velocity := player.get_real_velocity()
	text = """
	
	
	
	
	
	Speed:        %.2f m/s
	Ground speed: %.2f m/s (%3.0f%%)
	Velocity:     (%5.2f, %5.2f)""" % [
		velocity.length(),
		Vector2(velocity.x, velocity.z).length(),
		Vector2(velocity.x, velocity.z).length() / player.MAX_GROUND_SPEED * 100,
		velocity.x,
		velocity.z,
	]
