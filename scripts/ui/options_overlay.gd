extends Control

@export var pause_game_when_open := false
@export var title_text := "Options"
@export var menu_sounds: NodePath

@onready var options_panel: PanelContainer = $OptionsPanel
@onready var options_close: Button = $OptionsCloseButton
@onready var title_label: Label = $OptionsPanel/Margin/Column/Title
@onready var volume_slider: HSlider = $OptionsPanel/Margin/Column/MasterVolumeRow/VolumeSlider
@onready var volume_value: Label = $OptionsPanel/Margin/Column/MasterVolumeRow/VolumeValue
@onready var music_slider: HSlider = $OptionsPanel/Margin/Column/MusicVolumeRow/MusicSlider
@onready var music_value: Label = $OptionsPanel/Margin/Column/MusicVolumeRow/MusicValue
@onready var sfx_slider: HSlider = $OptionsPanel/Margin/Column/SfxVolumeRow/SfxSlider
@onready var sfx_value: Label = $OptionsPanel/Margin/Column/SfxVolumeRow/SfxValue
@onready var vsync_toggle: CheckButton = $OptionsPanel/Margin/Column/VsyncToggle

var _menu_sounds: Node
var _slider_previous: Dictionary = {}


func _ready() -> void:
	if pause_game_when_open:
		process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if menu_sounds != NodePath():
		_menu_sounds = get_node(menu_sounds)
	volume_slider.value_changed.connect(
		func(v: float) -> void: _on_volume_changed(volume_slider, v, volume_value, "Master")
	)
	music_slider.value_changed.connect(
		func(v: float) -> void: _on_volume_changed(music_slider, v, music_value, "Music")
	)
	sfx_slider.value_changed.connect(
		func(v: float) -> void: _on_volume_changed(sfx_slider, v, sfx_value, "SFX")
	)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	options_close.pressed.connect(func() -> void: close(_play_back_on_close()))
	_sync_from_disk()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED or not is_node_ready() or not visible:
		return
	_position_options_close()


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	title_label.text = title_text
	visible = true
	move_to_front()
	call_deferred("_position_options_close")
	if pause_game_when_open:
		get_tree().paused = true
		GameUI.set_movement_locked(true)


func close(play_back_sound: bool = false) -> void:
	if not visible:
		return
	_persist()
	if play_back_sound and _menu_sounds:
		_menu_sounds.play_back()
	visible = false
	if not pause_game_when_open:
		return
	get_tree().paused = false
	var ui := GameUI.get_root()
	GameUI.set_movement_locked(ui != null and ui.conversation_active)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close(_play_back_on_close())
		get_viewport().set_input_as_handled()


func _play_back_on_close() -> bool:
	return _menu_sounds != null and not pause_game_when_open


func _position_options_close() -> void:
	if options_close == null or options_panel == null:
		return
	var hang := Vector2(18, 18)
	var button_size = options_close.size
	if button_size == Vector2.ZERO:
		button_size = Vector2(40, 40)
	options_close.position = options_panel.position + Vector2(-button_size.x + hang.x, -hang.y)


func _sync_from_disk() -> void:
	var levels := Audio.read_audio_levels()
	volume_slider.set_value_no_signal(levels.x)
	music_slider.set_value_no_signal(levels.y)
	sfx_slider.set_value_no_signal(levels.z)
	vsync_toggle.set_pressed_no_signal(Audio.read_vsync())
	_apply_sliders_to_audio()


func _persist() -> void:
	Audio.persist_settings(
		volume_slider.value,
		music_slider.value,
		sfx_slider.value,
		vsync_toggle.button_pressed,
	)


func _apply_sliders_to_audio() -> void:
	Audio.apply_audio_levels(volume_slider.value, music_slider.value, sfx_slider.value)
	Audio.apply_vsync(vsync_toggle.button_pressed)
	_update_percent_label(volume_value, volume_slider.value)
	_update_percent_label(music_value, music_slider.value)
	_update_percent_label(sfx_value, sfx_slider.value)
	for slider: HSlider in [volume_slider, music_slider, sfx_slider]:
		_slider_previous[slider.get_instance_id()] = slider.value


func _on_volume_changed(slider: HSlider, value: float, label: Label, bus_name: String) -> void:
	var id := slider.get_instance_id()
	var previous: float = _slider_previous.get(id, value)
	if _menu_sounds:
		if value > previous:
			_menu_sounds.play_slider_right()
		elif value < previous:
			_menu_sounds.play_slider_left()
	_slider_previous[id] = value
	Audio.set_bus_volume(bus_name, value)
	_update_percent_label(label, value)


func _on_vsync_toggled(enabled: bool) -> void:
	if _menu_sounds:
		_menu_sounds.play_click()
	Audio.apply_vsync(enabled)


func _update_percent_label(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)
