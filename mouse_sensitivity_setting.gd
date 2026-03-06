extends VBoxContainer

@export var slider: Range
@export var input: Range
@export var player: Player

func _ready() -> void:
	slider.value_changed.connect(update_value)
	input.value_changed.connect(update_value)
	slider.value = player.mouse_sensitivity

func update_value(value: float) -> void:
	player.mouse_sensitivity = value
	slider.value = value
	input.value = value
