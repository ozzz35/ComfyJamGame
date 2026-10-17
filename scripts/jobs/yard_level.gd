extends Node2D

@onready var garden_area: Polygon2D = $GardenArea
@onready var exit : Area2D = $Exit
var _yard_ghost: Node2D
var _gilbert_finale: Node2D
var _player: PlayerBase

var percent_oc : float = 0.0
var starting_leaves : int = 0
var job_status : bool = false
var leaves_cleared : int = 0

@export var job_goal : float = 0.98

var _leaving := false
var _exit_unlocked := false
var _finale_pulled_back := false
var _tools: Node
var _garden_bounds := Rect2()
var _ui: Control
var _ui_hooks_bound := false

const JOB3_GHOST_BLOCK := &"job3_ghost"
const JOB3_EVIDENCE_BLOCK := &"job3_ghost_evidence"
const JOB3_FINALE_BLOCK := &"job3_finale"
const JOB3_EPILOGUE_BLOCK := &"job3_epilogue"
const JOB3_YARD_START_BLOCK := &"job3_gilbert_yard_start"

func _ready() -> void:
	_play_yard_music()
	_garden_bounds = _bounds_from_polygon(garden_area.polygon)
	starting_leaves = _count_leaves()
	exit.monitoring = false
	_yard_ghost = get_node_or_null("Ghost") as Node2D
	_gilbert_finale = get_node_or_null("GilbertFinale") as Node2D
	if _yard_ghost and _is_job3_yard():
		_yard_ghost.visible = false
	if _gilbert_finale:
		_gilbert_finale.visible = false
	_player = find_child("Player", true, false) as PlayerBase
	if _player:
		_tools = _player.find_child("Tools", true, false)
	_setup_ui()

func _setup_ui() -> void:
	var existing := GameUI.get_root()
	if existing:
		_ui = existing
		_bind_ui_hooks()
		_try_begin_yard_ui()
		return
	GameUI.root_changed.connect(_on_ui_root_changed, CONNECT_ONE_SHOT)

func _on_ui_root_changed(root: Control) -> void:
	_ui = root
	_bind_ui_hooks()
	_try_begin_yard_ui()

func _bind_ui_hooks() -> void:
	if _ui == null or _ui_hooks_bound:
		return
	_ui_hooks_bound = true
	if not _ui.conversation_finished.is_connected(_on_conversation_finished):
		_ui.conversation_finished.connect(_on_conversation_finished)
	if not _ui.dialogue_line.is_connected(_on_dialogue_line):
		_ui.dialogue_line.connect(_on_dialogue_line)
	if not _ui.dialogue_action.is_connected(_on_dialogue_action):
		_ui.dialogue_action.connect(_on_dialogue_action)

func _try_begin_yard_ui() -> void:
	if _ui == null:
		return
	if GameManager.current_job is JobData:
		var data := GameManager.current_job as JobData
		if data.job_number == 3:
			_end_yard_dialogue_camera()
		_ui.begin_yard(data)

func _process(_delta: float) -> void:
	if _tools == null or _ui == null:
		return
	_ui.set_vacuum_fill(_tools.get_vacuum_storage_ratio())

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_push_leaves"):
		return
	_cheat_clear_leaves()
	get_viewport().set_input_as_handled()

func _cheat_clear_leaves() -> void:
	for node in find_children("*", "", true, false):
		if not node is Leaf:
			continue
		if node.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		leaf_removed()
		node.queue_free()

func _count_leaves() -> int:
	var total : int = 0
	for node in find_children("*", "", true, false):
		if node.has_method("receive_gust"):
			total += 1
	return total

func contains_world_point(world_position: Vector2) -> bool:
	var local_point := garden_area.to_local(world_position)
	if not _garden_bounds.has_point(local_point):
		return false
	return Geometry2D.is_point_in_polygon(local_point, garden_area.polygon)

func _bounds_from_polygon(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var min_p := polygon[0]
	var max_p := polygon[0]
	for point in polygon:
		min_p = min_p.min(point)
		max_p = max_p.max(point)
	return Rect2(min_p, max_p - min_p)

func leaf_removed() -> void:
	leaves_cleared += 1
	if starting_leaves > 0:
		percent_oc = snapped(float(leaves_cleared) / float(starting_leaves), 0.01)
	if _ui:
		_ui.job_progress(minf(percent_oc * 100.0, 100.0))
	if job_status:
		return
	if percent_oc >= job_goal:
		job_status = true
		job_finished()

func job_finished() -> void:
	if _ui == null:
		return
	if _begin_job3_ghost_debrief():
		return
	_ui.show_job_complete_banner()
	_unlock_exit()
	if GameManager.current_job is JobData:
		var data := GameManager.current_job as JobData
		if data.completion_dialogue_block != &"":
			var path := DialogueLibrary.resolve_path(data.dialogue_file)
			_ui.start_conversation(path, data.completion_dialogue_block)

func _begin_job3_ghost_debrief() -> bool:
	if not GameManager.current_job is JobData:
		return false
	var data := GameManager.current_job as JobData
	if data.job_number != 3 or _yard_ghost == null:
		return false
	_ui.hide_job_complete_banner()
	if _yard_ghost:
		_yard_ghost.visible = true
	var path := DialogueLibrary.resolve_path(data.dialogue_file)
	_ui.start_conversation(path, JOB3_GHOST_BLOCK)
	return true

func _on_conversation_finished(block_id: StringName) -> void:
	if not GameManager.current_job is JobData:
		return
	var data := GameManager.current_job as JobData
	if data.job_number != 3:
		_end_yard_dialogue_camera()
		return
	var path := DialogueLibrary.resolve_path(data.dialogue_file)
	match block_id:
		JOB3_YARD_START_BLOCK:
			_end_yard_dialogue_camera()
		JOB3_GHOST_BLOCK:
			_ui.start_conversation(path, JOB3_EVIDENCE_BLOCK)
		JOB3_EVIDENCE_BLOCK:
			_ui.start_conversation(path, JOB3_FINALE_BLOCK)
		JOB3_FINALE_BLOCK:
			_ui.start_conversation(path, JOB3_EPILOGUE_BLOCK)
		JOB3_EPILOGUE_BLOCK:
			_end_yard_dialogue_camera()
			GameManager.job3_done = true

func _end_yard_dialogue_camera() -> void:
	if _player == null:
		return
	var cam := _player.get_node_or_null("Camera") as Camera2D
	if cam:
		cam.set_dialogue_focus(false)

func _on_dialogue_line(line: Dictionary) -> void:
	if _player == null or _ui == null or not _ui.conversation_active:
		return
	if GameManager.current_job is JobData:
		var data := GameManager.current_job as JobData
		if data.job_number == 3 and not job_status:
			return
	var focus_id := str(line.get("focus", ""))
	if focus_id.is_empty():
		return
	var cam := _player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	var focus_pos := DialogueFocus.global_position(self, focus_id, _player)
	if focus_pos == Vector2.ZERO:
		return
	cam.set_dialogue_focus(true, focus_pos)
	_pull_back_for_finale(cam, focus_id)

func _pull_back_for_finale(cam: Camera2D, focus_id: String) -> void:
	if _finale_pulled_back or focus_id != "gilbert":
		return
	if _gilbert_finale == null or not _gilbert_finale.visible:
		return
	_finale_pulled_back = true
	cam.pull_back()

func _on_dialogue_action(action: StringName) -> void:
	match action:
		&"reveal_gilbert":
			if _gilbert_finale:
				_gilbert_finale.visible = true
		&"ghost_glow":
			_tween_ghost_modulate(1.35, 0.6)
		&"ghost_fade":
			_tween_ghost_modulate(0.0, 1.2, true)
		&"start_credits":
			Audio.play_music("finale", 2.0)
			if _ui:
				_ui.show_credits()

func _tween_ghost_modulate(target_alpha: float, duration: float, hide_after: bool = false) -> void:
	if _yard_ghost == null:
		return
	var tween := create_tween()
	tween.tween_property(_yard_ghost, "modulate:a", target_alpha, duration)
	if hide_after:
		tween.tween_callback(func() -> void: _yard_ghost.visible = false)

func _unlock_exit() -> void:
	if _exit_unlocked:
		return
	_exit_unlocked = true
	exit.monitoring = true

func _on_exit_body_entered(body: Node2D) -> void:
	_leave_through_exit(body)

func _leave_through_exit(body: Node) -> void:
	if _leaving or not job_status or not _exit_unlocked or not body is PlayerBase:
		return
	_leaving = true
	if _ui:
		_ui.hide_job_complete_banner()
		_ui.cancel_conversation()
		_ui.hide_help()
	GameManager.leave_job.call_deferred()


func _is_job3_yard() -> bool:
	return GameManager.current_job is JobData and (GameManager.current_job as JobData).job_number == 3


func _play_yard_music() -> void:
	if GameManager.current_job is JobData:
		var data := GameManager.current_job as JobData
		if data.job_number == 3:
			Audio.play_music("battle")
			return
	Audio.start_music_playlist(MusicTracks.YARD_PLAYLIST)
