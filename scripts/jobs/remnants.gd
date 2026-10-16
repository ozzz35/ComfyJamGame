extends Node2D

const GLITCH_SHADER := preload("res://shaders/glitch_screen.gdshader")

@export var remnant_sprite: Sprite2D
@export var remnant_sprite_texture: Texture2D
@export var blindness_fade: float = 0.3
@export var blindness_hold: float = 0.3

var time_treshold: float = 4
var current_time_treshold: float = 0
enum State { BURIED, REVEALED, VANISHING, GONE }
@onready var covered_area: Area2D = $CoveredArea
var state
var witnessed = false

func _ready() -> void:
	state = State.BURIED
	current_time_treshold = time_treshold
	remnant_sprite.texture = remnant_sprite_texture

func _process(delta: float) -> void:
	if state == State.BURIED:
		if covered_area.get_overlapping_areas().size() <= 5:
			state = State.REVEALED
	if state == State.REVEALED and witnessed:
		current_time_treshold -= delta
		if current_time_treshold <= 0:
			_begin_vanish()

func _on_covered_area_body_entered(body: Node2D) -> void:
	if not body is PlayerBase:
		return
	witnessed = true

func _begin_vanish() -> void:
	if state == State.VANISHING or state == State.GONE:
		return
	state = State.VANISHING
	blindness()

func blindness() -> void:
	var ui := GameUI.get_root()
	if ui == null:
		return

	GameUI.set_movement_locked(true)
	Audio.set_music_paused(true)
	Audio.begin_remnant_vanish_audio()

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 50
	ui.add_child(overlay)
	overlay.move_to_front()

	var black := _fullscreen_color_rect(Color.BLACK)
	black.modulate.a = 0.0
	overlay.add_child(black)

	var glitch := _fullscreen_color_rect(Color.WHITE)
	var glitch_material := ShaderMaterial.new()
	glitch_material.shader = GLITCH_SHADER
	glitch.material = glitch_material
	glitch.visible = false
	overlay.add_child(glitch)

	var tween := create_tween()
	_black_pulse(tween, black, glitch, true)
	_black_pulse(tween, black, glitch, false)
	tween.tween_callback(func() -> void:
		state = State.GONE
		Audio.end_remnant_vanish_audio()
		Audio.set_music_paused(false)
		GameUI.set_movement_locked(false)
		overlay.queue_free()
	)

func _black_pulse(tween: Tween, black: ColorRect, glitch: ColorRect, hide_remnant: bool) -> void:
	tween.tween_property(black, "modulate:a", 1.0, blindness_fade)
	tween.tween_callback(func() -> void:
		glitch.visible = true
		if hide_remnant:
			_hide_remnant_sprite()
	)
	tween.tween_interval(blindness_hold)
	tween.tween_callback(func() -> void:
		glitch.visible = false
	)
	tween.tween_property(black, "modulate:a", 0.0, blindness_fade)

func _fullscreen_color_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.set_offsets_preset(Control.PRESET_FULL_RECT)
	rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _hide_remnant_sprite() -> void:
	if remnant_sprite:
		remnant_sprite.visible = false
