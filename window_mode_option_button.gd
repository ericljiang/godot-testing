extends OptionButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_selected.connect(on_selected)
	# TODO don't assume there is only 1 window
	match DisplayServer.window_get_mode(0):
		Window.Mode.MODE_WINDOWED:
			select(0)
		Window.Mode.MODE_FULLSCREEN:
			select(1)

func on_selected(index: int) -> void:
	print("selected %s" % index)
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
