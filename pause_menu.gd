extends Control

@export var resume_button: Button
@export var quit_button: Button

func _ready() -> void:
	assert(resume_button != null)
	assert(quit_button != null)
	resume_button.pressed.connect(unpause)
	quit_button.pressed.connect(quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_visible_in_tree():
			unpause()
		else:
			pause()

func pause() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func unpause() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()

func quit() -> void:
	get_tree().quit()
