extends Node2D

## Jobs this NPC can offer, in order. First entry that GameManager allows is shown.
@export var offered_jobs: Array[JobData] = []
@export_file("*.json") var dialogue_file: String = "res://dialogue/foreman.json"
@export var no_work_dialogue_block: StringName = &"no_work"
@export var talk_focus: Node2D

@onready var area: Area2D = $TalkArea2D

var player_here := false
var player: PlayerBase
var _offered_job: JobData
var _ui: Control

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

func _process(_delta: float) -> void:
	if _ui == null or not player_here or _ui.conversation_active:
		return
	var pos := get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16))
	_ui.talk_prompt(true, pos)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _ui == null or _ui.conversation_active:
		return
	if not player_here or not event.is_action_pressed("interact"):
		return
	# Later: open a small menu (ask for work / ask about them) before starting dialogue.
	get_viewport().set_input_as_handled()
	var offer := _next_job()
	if offer != null:
		_begin_job_offer(offer)
	else:
		_begin_no_work_talk()

func _begin_job_offer(offer: JobData) -> void:
	_offered_job = offer
	_ui.talk_prompt(false, Vector2.ZERO)
	var path := dialogue_file
	if offer.dialogue_file != "":
		path = offer.dialogue_file
	_set_camera_dialogue(true)
	_ui.start_conversation(path, offer.offer_dialogue_block)

func _begin_no_work_talk() -> void:
	_offered_job = null
	_ui.talk_prompt(false, Vector2.ZERO)
	_set_camera_dialogue(true)
	if not _ui.start_conversation(dialogue_file, no_work_dialogue_block):
		_set_camera_dialogue(false)

func _next_job() -> JobData:
	for job in offered_jobs:
		if GameManager.can_offer_job(job):
			return job
	return null

func _on_conversation_finished(block_id: StringName) -> void:
	_set_camera_dialogue(false)
	if _offered_job == null:
		return
	if block_id == _offered_job.offer_dialogue_block:
		GameManager.start_job(_offered_job)
	_offered_job = null

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
