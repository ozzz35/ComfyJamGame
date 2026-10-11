extends Camera2D

@export var max_offset_distance: float = 100.0
@export var smoothness: float = 2.0

const DEFAULT_SHAKE_DURATION := 0.18

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


func _unhandled_input(event: InputEvent) -> void:
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


func update_camera_offset(delta: float) -> void:
	var max_offset_y := _max_downward_offset()
	var base_target := _clamp_downward(_mouse_look_target(), max_offset_y)
	var weight: float = clampf(delta * smoothness, 0.0, 1.0)
	_smoothed_offset = _smoothed_offset.lerp(base_target, weight)
	_smoothed_offset = _clamp_downward(_smoothed_offset, max_offset_y)
	_advance_shake(delta)
	offset = _clamp_downward(_smoothed_offset + _shake_offset, max_offset_y)


func _mouse_look_target() -> Vector2:
	var screen_center := get_viewport_rect().size * 0.5
	var screen_delta := get_viewport().get_mouse_position() - screen_center
	var diff := screen_delta / zoom
	if diff.length() > max_offset_distance:
		diff = diff.normalized() * max_offset_distance
	return original_offset + diff


func _clamp_downward(point: Vector2, max_offset_y: float) -> Vector2:
	if point.y > max_offset_y:
		point.y = max_offset_y
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


func shake(strength: float, duration) -> void:
	_shake_current_strength = strength
	_shake_time = duration
	_shake_jitter_speed = clamp(12.0 + strength * 4.0, 12.0, 80.0)


func zoom_in_out_effect(peak_zoom: float = 1.35, target_final_zoom: float = 1.0) -> void:
	if _zoom_tween and _zoom_tween.is_running():
		_zoom_tween.kill()

	target_scale = target_final_zoom
	_zoom_tween = create_tween()
	
	_zoom_tween.set_trans(Tween.TRANS_EXPO)
	_zoom_tween.tween_property(self, "zoom", Vector2(peak_zoom, peak_zoom), 0.1)
	
	_zoom_tween.set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(self, "zoom", Vector2(target_final_zoom, target_final_zoom), 0.9).set_delay(0.07)
