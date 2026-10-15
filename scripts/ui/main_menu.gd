extends Control

const GAME_SCENE := "res://scenes/main/main.tscn"
const SETTINGS_PATH := "user://settings.cfg"

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var options_close: Button = $OptionsCloseButton
@onready var ui_sounds: Node = $UISounds
@onready var volume_slider: HSlider = $OptionsPanel/Margin/Column/MasterVolumeRow/VolumeSlider
@onready var volume_value: Label = $OptionsPanel/Margin/Column/MasterVolumeRow/VolumeValue
@onready var music_slider: HSlider = $OptionsPanel/Margin/Column/MusicVolumeRow/MusicSlider
@onready var music_value: Label = $OptionsPanel/Margin/Column/MusicVolumeRow/MusicValue
@onready var sfx_slider: HSlider = $OptionsPanel/Margin/Column/SfxVolumeRow/SfxSlider
@onready var sfx_value: Label = $OptionsPanel/Margin/Column/SfxVolumeRow/SfxValue
@onready var vsync_toggle: CheckButton = $OptionsPanel/Margin/Column/VsyncToggle

var _slider_previous: Dictionary = {}

func _ready() -> void:
	_set_options_open(false)
	_load_settings()
	_wire_option_controls()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what != NOTIFICATION_RESIZED:
		return
	if options_panel == null or options_close == null:
		return
	if not options_panel.visible:
		return
	_position_options_close()

func _wire_option_controls() -> void:
	volume_slider.value_changed.connect(
		func(value: float) -> void: _on_volume_slider_changed(volume_slider, value, volume_value, "Master")
	)
	music_slider.value_changed.connect(
		func(value: float) -> void: _on_volume_slider_changed(music_slider, value, music_value, "Music")
	)
	sfx_slider.value_changed.connect(
		func(value: float) -> void: _on_volume_slider_changed(sfx_slider, value, sfx_value, "SFX")
	)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	vsync_toggle.mouse_entered.connect(_on_menu_button_hovered)

	for button: Button in _menu_buttons():
		button.pressed.connect(_on_menu_button_pressed.bind(button))
		button.mouse_entered.connect(_on_menu_button_hovered)

	options_close.pressed.connect(_on_options_close_pressed)
	options_close.mouse_entered.connect(_on_menu_button_hovered)

	_snapshot_slider_values()

func _snapshot_slider_values() -> void:
	for slider: HSlider in [volume_slider, music_slider, sfx_slider]:
		_slider_previous[slider.get_instance_id()] = slider.value

func _menu_buttons() -> Array[Button]:
	return [
		$MenuColumn/StartButton,
		$MenuColumn/OptionsButton,
		$MenuColumn/QuitButton,
	]

func _unhandled_input(event: InputEvent) -> void:
	if not options_panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_options(true)
		get_viewport().set_input_as_handled()

func _on_menu_button_pressed(button: Button) -> void:
	ui_sounds.play_click()
	if button == $MenuColumn/StartButton:
		_save_settings()
		get_tree().change_scene_to_file(GAME_SCENE)
	elif button == $MenuColumn/OptionsButton:
		_set_options_open(true)
	elif button == $MenuColumn/QuitButton:
		get_tree().quit()

func _on_menu_button_hovered() -> void:
	ui_sounds.play_hover()

func _on_options_close_pressed() -> void:
	_close_options(true)

func _close_options(play_back_sound: bool) -> void:
	if play_back_sound:
		ui_sounds.play_back()
	_set_options_open(false)
	_save_settings()

func _set_options_open(open: bool) -> void:
	if options_panel == null or dim_overlay == null or options_close == null:
		return
	options_panel.visible = open
	dim_overlay.visible = open
	options_close.visible = open
	if open:
		call_deferred("_position_options_close")

func _position_options_close() -> void:
	if options_panel == null or options_close == null:
		return
	options_close.position = _options_close_position()

func _options_close_position() -> Vector2:
	var hang := Vector2(18, 18)
	var button_size := options_close.size
	if button_size == Vector2.ZERO:
		button_size = Vector2(40, 40)
	return options_panel.position + Vector2(-button_size.x + hang.x, -hang.y)

func _on_volume_slider_changed(slider: HSlider, value: float, label: Label, bus_name: String) -> void:
	var id := slider.get_instance_id()
	var previous: float = _slider_previous.get(id, value)
	if value > previous:
		ui_sounds.play_slider_right()
	elif value < previous:
		ui_sounds.play_slider_left()
	_slider_previous[id] = value
	_apply_bus_volume(bus_name, value)
	_update_percent_label(label, value)

func _on_vsync_toggled(enabled: bool) -> void:
	ui_sounds.play_click()
	_apply_vsync(enabled)

func _apply_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)

func _update_percent_label(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)

func _apply_bus_volume(bus_name: String, value: float) -> void:
	Audio.set_bus_volume(bus_name, value)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		_apply_defaults()
		return

	volume_slider.set_value_no_signal(float(cfg.get_value("audio", "master", 1.0)))
	music_slider.set_value_no_signal(float(cfg.get_value("audio", "music", 1.0)))
	sfx_slider.set_value_no_signal(float(cfg.get_value("audio", "sfx", 1.0)))
	vsync_toggle.set_pressed_no_signal(bool(cfg.get_value("display", "vsync", true)))

	_apply_all_settings_from_ui()

func _apply_defaults() -> void:
	volume_slider.set_value_no_signal(1.0)
	music_slider.set_value_no_signal(1.0)
	sfx_slider.set_value_no_signal(1.0)
	vsync_toggle.set_pressed_no_signal(true)
	_apply_all_settings_from_ui()

func _apply_all_settings_from_ui() -> void:
	_apply_bus_volume("Master", volume_slider.value)
	_update_percent_label(volume_value, volume_slider.value)
	_apply_bus_volume("Music", music_slider.value)
	_update_percent_label(music_value, music_slider.value)
	_apply_bus_volume("SFX", sfx_slider.value)
	_update_percent_label(sfx_value, sfx_slider.value)
	_apply_vsync(vsync_toggle.button_pressed)
	_snapshot_slider_values()

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", volume_slider.value)
	cfg.set_value("audio", "music", music_slider.value)
	cfg.set_value("audio", "sfx", sfx_slider.value)
	cfg.set_value("display", "vsync", vsync_toggle.button_pressed)
	cfg.save(SETTINGS_PATH)
