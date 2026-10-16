extends Node2D

## Jobs this NPC can offer, in order. First entry that GameManager allows is shown.
@export var offered_jobs: Array[JobData] = []
@export_file("*.json") var dialogue_file: String = "res://dialogue/game_dialogue.json"
@export var no_work_dialogue_block: StringName = &"no_work"
## When prerequisites for offered job(s) are not met (e.g. talk to Jane before Gilbert).
@export var blocked_dialogue_block: StringName = &""
## When every non-tutorial job this NPC offers is already completed.
@export var after_jobs_done_dialogue_block: StringName = &""
## Small-talk when the player picks "Ask about them" on the talk menu.
@export var about_dialogue_block: StringName = &""
@export var talk_focus: Node2D
## After the menu intro, auto-play the next job offer (Gilbert tutorial on the hub).
@export var run_intro_hub_greeting := false

@onready var area: Area2D = $TalkArea2D

var player_here := false
var player: PlayerBase
var _offered_job: JobData
var _ui: Control
var _conversation_host := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_setup_ui()

func _setup_ui() -> void:
	var existing := GameUI.get_root()
	if existing:
		_bind_ui(existing)
		return
	GameUI.root_changed.connect(_bind_ui, CONNECT_ONE_SHOT)

func _bind_ui(ui_node: Control) -> void:
	if _ui != null:
		return
	_ui = ui_node
	_ui.conversation_finished.connect(_on_conversation_finished)
	if not _ui.dialogue_line.is_connected(_on_dialogue_line):
		_ui.dialogue_line.connect(_on_dialogue_line)
	if run_intro_hub_greeting:
		call_deferred("_run_intro_hub_greeting_when_ready")

func _run_intro_hub_greeting_when_ready() -> void:
	if not GameManager.greet_gilbert_on_hub_load:
		return
	if _ui == null:
		return
	if GameManager.hub_fade_in_on_load or _ui.is_hub_fade_in_running():
		if not _ui.hub_fade_in_finished.is_connected(_try_intro_hub_greeting):
			_ui.hub_fade_in_finished.connect(_try_intro_hub_greeting, CONNECT_ONE_SHOT)
		return
	_try_intro_hub_greeting()

func _process(_delta: float) -> void:
	if _ui == null or not player_here or _ui.conversation_active or _ui.talk_choice_active:
		return
	var pos := get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16))
	_ui.talk_prompt(true, pos)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _ui == null or _ui.conversation_active or _ui.talk_choice_active:
		return
	if not player_here or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_begin_talk_menu()

func _try_intro_hub_greeting() -> void:
	if not run_intro_hub_greeting or not GameManager.greet_gilbert_on_hub_load:
		return
	GameManager.greet_gilbert_on_hub_load = false
	var offer := _next_job()
	if offer == null:
		return
	_ensure_player()
	if player == null:
		return
	_begin_job_offer(offer)

func _ensure_player() -> void:
	if player != null:
		return
	var found := get_tree().current_scene.find_child("Player", true, false)
	if found is PlayerBase:
		player = found

func _begin_talk_menu() -> void:
	_conversation_host = true
	_ui.talk_prompt(false, Vector2.ZERO)
	_set_camera_dialogue(true)
	if about_dialogue_block == &"":
		_begin_work_talk()
		return
	_ui.show_talk_choice(_on_talk_menu_picked)

func _on_talk_menu_picked(choice: StringName) -> void:
	if choice.is_empty():
		_conversation_host = false
		_set_camera_dialogue(false)
		return
	if choice == &"about":
		_offered_job = null
		_start_dialogue(about_dialogue_block)
	else:
		_begin_work_talk()

func _begin_work_talk() -> void:
	var offer := _next_job()
	if offer != null:
		_begin_job_offer(offer)
	else:
		_offered_job = null
		_start_dialogue(_resolve_no_work_block())

func _start_dialogue(block_id: StringName) -> void:
	_conversation_host = true
	var path := DialogueLibrary.resolve_path(dialogue_file)
	if not _ui.start_conversation(path, block_id):
		_conversation_host = false
		_set_camera_dialogue(false)

func _begin_job_offer(offer: JobData) -> void:
	_conversation_host = true
	_offered_job = offer
	_ui.talk_prompt(false, Vector2.ZERO)
	var path := DialogueLibrary.resolve_path(dialogue_file)
	if offer.dialogue_file != "":
		path = DialogueLibrary.resolve_path(offer.dialogue_file)
	_set_camera_dialogue(true)
	if not _ui.start_conversation(path, offer.offer_dialogue_block):
		_conversation_host = false
		_set_camera_dialogue(false)

func _next_job() -> JobData:
	for job in offered_jobs:
		if GameManager.can_offer_job(job):
			return job
	return null

func _resolve_no_work_block() -> StringName:
	for job in offered_jobs:
		if GameManager.can_offer_job(job):
			return no_work_dialogue_block
	if blocked_dialogue_block != &"":
		for job in offered_jobs:
			if job.is_tutorial:
				continue
			if not _job_prerequisites_met(job) and not _job_marked_done(job):
				return blocked_dialogue_block
	if after_jobs_done_dialogue_block != &"" and _all_offered_jobs_done():
		return after_jobs_done_dialogue_block
	return no_work_dialogue_block

func _job_prerequisites_met(job: JobData) -> bool:
	if job.is_tutorial:
		return true
	if not GameManager.tutorial_done:
		return false
	for n in range(1, job.job_number):
		if not GameManager.is_job_done(n):
			return false
	return true

func _job_marked_done(job: JobData) -> bool:
	if job.is_tutorial:
		return GameManager.tutorial_done
	return GameManager.is_job_done(job.job_number)

func _all_offered_jobs_done() -> bool:
	if offered_jobs.is_empty():
		return false
	for job in offered_jobs:
		if job.is_tutorial:
			if not GameManager.tutorial_done:
				return false
		elif not GameManager.is_job_done(job.job_number):
			return false
	return true

func _on_conversation_finished(block_id: StringName) -> void:
	if _conversation_host:
		_set_camera_dialogue(false)
	_conversation_host = false
	if _offered_job == null:
		return
	if block_id == _offered_job.offer_dialogue_block:
		GameManager.start_job(_offered_job)
	_offered_job = null

func _on_dialogue_line(line: Dictionary) -> void:
	if not _conversation_host or _ui == null or not _ui.conversation_active or player == null:
		return
	var focus_id := str(line.get("focus", ""))
	var focus_pos := Vector2.ZERO
	if not focus_id.is_empty():
		focus_pos = DialogueFocus.global_position(get_tree().current_scene, focus_id, player)
	if focus_pos == Vector2.ZERO:
		return
	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	cam.set_dialogue_focus(true, focus_pos)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		player = body
		player_here = true

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerBase:
		player_here = false
		if _ui:
			_ui.talk_prompt(false, Vector2.ZERO)

func _set_camera_dialogue(on: bool) -> void:
	if player == null:
		return
	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	var focus := global_position
	if talk_focus:
		focus = talk_focus.global_position
	cam.set_dialogue_focus(on, focus)
