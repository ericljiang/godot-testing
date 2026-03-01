extends Area3D

@export var player: Player
@export var movement_type: Player.MovementType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(player != null, "ERROR: `player` not configured for this button.");
	assert(movement_type != null, "ERROR: `movement_type` not configured for this button.");
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node3D) -> void:
	print("entered %s" % movement_type)
	player.movement_type = movement_type
	player.reset_movement_parameters()
