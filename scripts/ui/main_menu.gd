extends Control

@onready var options_overlay: Control = $OptionsOverlay
@onready var ui_sounds: Node = $UISounds
@onready var intro: Node = $Intro


func _ready() -> void:
	Audio.play_music("menu")
	_wire_menu_buttons()


func _wire_menu_buttons() -> void:
	for button: Button in _menu_buttons():
		button.pressed.connect(_on_menu_button_pressed.bind(button))
		button.mouse_entered.connect(_on_menu_button_hovered)


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
		intro.start()
	elif button == $MenuColumn/OptionsButton:
		options_overlay.open()
	elif button == $MenuColumn/QuitButton:
		get_tree().quit()


func _on_menu_button_hovered() -> void:
	ui_sounds.play_hover()
