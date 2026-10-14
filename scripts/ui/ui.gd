extends Control

signal conversation_finished(block_id: StringName)

@onready var money_label : Label = $MoneyLabel
@onready var job_pgbar : TextureProgressBar = $JobProgress
@onready var job_pglabel : Label = $JobProgressLabel
@onready var job_startprompt : Label = $JobStartPrompt
@onready var job_finishedprompt : Label = $JobFinishedPrompt
@onready var text_box: Control = $TextBox
@onready var dialogue_label: Label = $TextBox/DialogueLabel

@export var show_job_progress: bool = false

var conversation_active := false
var _dialogue_cache: Dictionary = {}
var _lines: Array = []
var _line_index: int = 0
var _block_id: StringName = &""

func _ready():
	job_pgbar.visible = show_job_progress
	job_pglabel.visible = show_job_progress
	money_label.text = "Money: " + str(GameManager.money)

func _process(delta):
	pass

func _input(event: InputEvent) -> void:
	if not conversation_active:
		return
	if not _is_advance_input(event):
		return
	get_viewport().set_input_as_handled()
	_advance_line()

func _is_advance_input(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") or event.is_action_pressed("mouse_left")

func job_progress(progress):
	job_pgbar.value = progress

func update_ui():
	money_label.text = "Money: " + str(GameManager.money)

func jobstart_prompt(visibility : bool, pos : Vector2):
	job_startprompt.visible = visibility
	var half = job_startprompt.size / 2
	job_startprompt.position = pos - Vector2(job_startprompt.size.x * 0.5, job_startprompt.size.y)

func talk_prompt(visibility: bool, pos: Vector2) -> void:
	if visibility:
		job_startprompt.text = "Press E or click to talk"
	jobstart_prompt(visibility, pos)

func start_conversation(path: String, block_id: StringName) -> bool:
	var data := _load_dialogue(path)
	if not data.has(block_id):
		return false
	_lines = data[block_id]
	if _lines.is_empty():
		return false
	_block_id = block_id
	_line_index = 0
	conversation_active = true
	text_box.visible = true
	dialogue_label.text = str(_lines[0])
	return true

func _advance_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_close_conversation()
		return
	dialogue_label.text = str(_lines[_line_index])

func cancel_conversation() -> void:
	conversation_active = false
	text_box.visible = false
	dialogue_label.text = ""
	_lines.clear()
	_block_id = &""
	_line_index = 0

func _close_conversation() -> void:
	var finished_id := _block_id
	cancel_conversation()
	conversation_finished.emit(finished_id)

func _load_dialogue(path: String) -> Dictionary:
	if _dialogue_cache.has(path):
		return _dialogue_cache[path]
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_dialogue_cache[path] = parsed
		return parsed
	return {}
