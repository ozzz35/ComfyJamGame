extends Node2D

@export var job: JobData
@export_file("*.json") var dialogue_file: String = "res://dialogue/foreman.json"
@export var offer_block: StringName = &"job1_before"
@export_range(8, 600, 1) var range: int = 20:
	set(value):
		range = maxi(value, 1)
		_apply_range()

@onready var area: Area2D = $TalkArea2D
@onready var shape_node: CollisionShape2D = $TalkArea2D/CollisionShape2D
@onready var ui := $"../../../UI/UiRoot"

var player_here := false
var player: PlayerBase

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
	var pos := get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16))
	ui.talk_prompt(true, pos)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if ui.conversation_active:
		return
	if not player_here or not event.is_action_pressed("interact"):
		return
	if job == null or GameManager.is_job_done(job.job_number):
		return
	get_viewport().set_input_as_handled()
	ui.talk_prompt(false, Vector2.ZERO)
	ui.start_conversation(dialogue_file, offer_block)

func _on_conversation_finished(block_id: StringName) -> void:
	if block_id == offer_block and job != null:
		GameManager.start_job(job)

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
