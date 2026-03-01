extends Label

@export var player: CharacterBody3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var velocity := player.get_real_velocity()
	text = """
	
	
	
	
	
	Speed:        %.2f m/s
	Ground speed: %.2f m/s
	Velocity:     (%5.2f, %5.2f)""" % [
		velocity.length(),
		Vector2(velocity.x, velocity.z).length(),
		velocity.x,
		velocity.z,
	]
