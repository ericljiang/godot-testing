extends OptionButton

@export var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(player != null)
	item_selected.connect(on_selected)
	match player.movement_type:
		Player.MovementType.QUAKE:
			select(0)
		Player.MovementType.CS:
			select(1)
		Player.MovementType.TF2_SOLDIER:
			select(2)

func on_selected(index: int) -> void:
	print("selected %s" % index)
	match index:
		0:
			player.movement_type = Player.MovementType.QUAKE
		1:
			player.movement_type = Player.MovementType.CS
		2:
			player.movement_type = Player.MovementType.TF2_SOLDIER
	player.reset_movement_parameters()
