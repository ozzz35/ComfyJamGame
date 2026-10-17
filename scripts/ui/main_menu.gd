extends Control

@onready var options_overlay: Control = $OptionsOverlay
@onready var ui_sounds: Node = $UISounds
@onready var intro: Node = $Intro

var _pressed_handlers: Dictionary = {}


func _ready() -> void:
	Audio.play_music("menu")
	_wire_menu_buttons()


func _wire_menu_buttons() -> void:
	for button: Button in _menu_buttons():
		var handler := _on_menu_button_pressed.bind(button)
		_pressed_handlers[button] = handler
		button.pressed.connect(handler)
		button.mouse_entered.connect(_on_menu_button_hovered)


func _unwire_menu_buttons() -> void:
	for button: Button in _menu_buttons():
		var handler: Callable = _pressed_handlers.get(button, Callable())
		if handler.is_valid() and button.pressed.is_connected(handler):
			button.pressed.disconnect(handler)
		if button.mouse_entered.is_connected(_on_menu_button_hovered):
			button.mouse_entered.disconnect(_on_menu_button_hovered)


func _menu_buttons() -> Array[Button]:
	return [
		$MenuColumn/StartButton,
		$MenuColumn/OptionsButton,
		$MenuColumn/QuitButton,
	]


func _on_menu_button_pressed(button: Button) -> void:
	ui_sounds.play_click()
	if button == $MenuColumn/StartButton:
		options_overlay.close()
		_unwire_menu_buttons()
		intro.start()
	elif button == $MenuColumn/OptionsButton:
		options_overlay.open()
	elif button == $MenuColumn/QuitButton:
		get_tree().quit()


func _on_menu_button_hovered() -> void:
	ui_sounds.play_hover()
