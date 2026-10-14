extends Node2D

@export var tutorial_job: JobData
@export var job1: JobData
@export var job2: JobData
@export var job3: JobData
@export_file("*.json") var dialogue_file: String = "res://dialogue/foreman.json"
@export_range(8, 600, 1) var range: int = 20:
	set(value):
		range = maxi(value, 1)
		_apply_range()

@onready var area: Area2D = $TalkArea2D
@onready var shape_node: CollisionShape2D = $TalkArea2D/CollisionShape2D
@onready var ui := $"../../../UI/UiRoot"

var player_here := false
var player: PlayerBase
var _offered_job: JobData

func _ready() -> void:
	_apply_range()
	if Engine.is_editor_hint():
		return
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	ui.conversation_finished.connect(_on_conversation_finished)

func _process(_delta: float) -> void:
	if not player_here or ui.conversation_active:
		return
	if _next_job() == null:
		return
	var pos := get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16))
	ui.talk_prompt(true, pos)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if ui.conversation_active:
		return
	if not player_here or not event.is_action_pressed("interact"):
		return
	var offer := _next_job()
	if offer == null:
		return
	get_viewport().set_input_as_handled()
	_offered_job = offer
	ui.talk_prompt(false, Vector2.ZERO)
	var path := dialogue_file
	if offer.dialogue_file != "":
		path = offer.dialogue_file
	ui.start_conversation(path, offer.offer_dialogue_block)

func _next_job() -> JobData:
	if tutorial_job and not GameManager.tutorial_done:
		return tutorial_job
	if job1 and not GameManager.job1_done:
		return job1
	if job2 and not GameManager.job2_done:
		return job2
	if job3 and not GameManager.job3_done:
		return job3
	return null

func _on_conversation_finished(block_id: StringName) -> void:
	if _offered_job == null:
		return
	if block_id == _offered_job.offer_dialogue_block:
		GameManager.start_job(_offered_job)
	_offered_job = null

func _apply_range() -> void:
	if not is_node_ready():
		return
	var circle := shape_node.shape as CircleShape2D
	if circle:
		circle.radius = range

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		player = body
		player_here = true

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerBase:
		player_here = false
		ui.talk_prompt(false, Vector2.ZERO)
