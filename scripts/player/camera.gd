extends Camera2D

@export var max_offset_distance: float = 100.0
@export var smoothness: float = 2.0

var original_offset: Vector2 = Vector2.ZERO
var _smoothed_offset: Vector2 = Vector2.ZERO

var _shake_time: float = 0.0
var _shake_current_strength: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_target: Vector2 = Vector2.ZERO

var _shake_damping: float = 8.0
var _shake_jitter_speed: float = 25.0


@export var min_scale: float = 4
@export var max_scale: float = 8
@export var zoom_step: float = 1.12
@export var smooth_speed: float = 8.0

var target_scale: float = 1.0
var _zoom_tween: Tween

var is_talking := false
var _talk_focus_global := Vector2.ZERO

@export var talk_smoothness: float = 5.0


func _unhandled_input(event: InputEvent) -> void:
	if is_talking:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(1.0 / zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(zoom_step)


func _change_zoom(factor: float) -> void:
	target_scale = clamp(target_scale * factor, min_scale, max_scale)


func _ready() -> void:
	original_offset = offset
	_smoothed_offset = original_offset
	randomize()
	_change_zoom(1.0)


func _physics_process(delta: float) -> void:
	update_camera_offset(delta)


func _process(delta: float) -> void:
	if not _zoom_tween or not _zoom_tween.is_running():
		var t = clamp(delta * smooth_speed, 0.0, 1.0)
		var current := zoom.x
		var new_scale = lerp(current, target_scale, t)
		zoom = Vector2(new_scale, new_scale)


func set_dialogue_focus(active: bool, focus_global: Vector2 = Vector2.ZERO) -> void:
	is_talking = active
	_talk_focus_global = focus_global


func update_camera_offset(delta: float) -> void:
	var max_offset_y := _max_downward_offset()
	var min_offset_y := _max_upward_offset()
	var base_target: Vector2
	if is_talking:
		var parent_2d := get_parent() as Node2D
		if parent_2d:
			base_target = _talk_focus_global - parent_2d.global_position
		else:
			base_target = original_offset
		base_target = _clamp_vertical(base_target, min_offset_y, max_offset_y)
		var talk_weight: float = clampf(delta * talk_smoothness, 0.0, 1.0)
		_smoothed_offset = _smoothed_offset.lerp(base_target, talk_weight)
		_smoothed_offset = _clamp_vertical(_smoothed_offset, min_offset_y, max_offset_y)
		_advance_shake(delta)
		offset = _clamp_vertical(_smoothed_offset + _shake_offset, min_offset_y, max_offset_y)
		return
	base_target = _clamp_vertical(_mouse_look_target(), min_offset_y, max_offset_y)
	var weight: float = clampf(delta * smoothness, 0.0, 1.0)
	_smoothed_offset = _smoothed_offset.lerp(base_target, weight)
	_smoothed_offset = _clamp_vertical(_smoothed_offset, min_offset_y, max_offset_y)
	_advance_shake(delta)
	offset = _clamp_vertical(_smoothed_offset + _shake_offset, min_offset_y, max_offset_y)


func _mouse_look_target() -> Vector2:
	var screen_center := get_viewport_rect().size * 0.5
	var screen_delta := get_viewport().get_mouse_position() - screen_center
	var diff := screen_delta / zoom
	if diff.length() > max_offset_distance:
		diff = diff.normalized() * max_offset_distance
	return original_offset + diff


func _clamp_vertical(point: Vector2, min_offset_y: float, max_offset_y: float) -> Vector2:
	point = _clamp_downward(point, max_offset_y)
	return _clamp_upward(point, min_offset_y)


func _clamp_downward(point: Vector2, max_offset_y: float) -> Vector2:
	if point.y > max_offset_y:
		point.y = max_offset_y
	return point

func _clamp_upward(point: Vector2, min_offset_y: float) -> Vector2:
	if point.y < min_offset_y:
		point.y = min_offset_y
	return point

func _advance_shake(delta: float) -> void:
	if _shake_time > 0:
		_shake_time -= delta
		_shake_current_strength = lerp(_shake_current_strength, 0.0, delta * _shake_damping)
		_shake_target = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_current_strength
		_shake_offset = _shake_offset.lerp(_shake_target, delta * _shake_jitter_speed)
	else:
		_shake_offset = _shake_offset.lerp(Vector2.ZERO, delta * _shake_jitter_speed)
		_shake_current_strength = 0.0
		_shake_time = 0.0


func _max_downward_offset() -> float:
	var half_height := get_viewport_rect().size.y * 0.5 / zoom.y
	var view_bottom: float = min(global_position.y + half_height, float(limit_bottom))
	return float(limit_bottom) - view_bottom

func _max_upward_offset() -> float:
	var half_height := get_viewport_rect().size.y * 0.5 / zoom.y
	var view_top: float = max(global_position.y - half_height, float(limit_top))
	return float(limit_top) - view_top

func shake(strength: float, duration) -> void:
	_shake_current_strength = strength
	_shake_time = duration
	_shake_jitter_speed = clamp(12.0 + strength * 4.0, 12.0, 80.0)


func pull_back_to_include(world_point: Vector2, zoom_factor: float = 0.8, delay: float = 0.7, duration: float = 1.1) -> void:
	var fit_zoom := zoom.x * zoom_factor
	if fit_zoom >= zoom.x - 0.05:
		return
	var shared_focus := _talk_focus_global.lerp(world_point, 0.5)
	target_scale = fit_zoom
	if _zoom_tween and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	if delay > 0.0:
		_zoom_tween.tween_interval(delay)
	_zoom_tween.tween_callback(func() -> void:
		_talk_focus_global = shared_focus
	)
	_zoom_tween.set_trans(Tween.TRANS_SINE)
	_zoom_tween.set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(self, "zoom", Vector2(fit_zoom, fit_zoom), duration)


func zoom_in_out_effect(peak_zoom: float = 1.35, target_final_zoom: float = 1.0) -> void:
	if _zoom_tween and _zoom_tween.is_running():
		_zoom_tween.kill()

	target_scale = target_final_zoom
	_zoom_tween = create_tween()
	
	_zoom_tween.set_trans(Tween.TRANS_EXPO)
	_zoom_tween.tween_property(self, "zoom", Vector2(peak_zoom, peak_zoom), 0.1)
	
	_zoom_tween.set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(self, "zoom", Vector2(target_final_zoom, target_final_zoom), 0.9).set_delay(0.07)
