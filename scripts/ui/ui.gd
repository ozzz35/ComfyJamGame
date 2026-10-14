extends Control

signal conversation_finished(block_id: StringName)

const TOOL_NAMES := {
	1: "Broom",
	2: "Rake",
	3: "Leaf vacuum",
	4: "Leaf blower",
}

@onready var yard_hud: Control = $YardHud
@onready var job_pgbar: TextureProgressBar = $YardHud/HudPanel/Margin/Column/JobProgress
@onready var job_pglabel: Label = $YardHud/HudPanel/Margin/Column/ProgressRow/ProgressLabel
@onready var progress_value: Label = $YardHud/HudPanel/Margin/Column/ProgressRow/ProgressValue
@onready var tool_label: Label = $YardHud/HudPanel/Margin/Column/ToolLabel
@onready var vacuum_row: HBoxContainer = $YardHud/HudPanel/Margin/Column/VacuumRow
@onready var vacuum_bar: TextureProgressBar = $YardHud/HudPanel/Margin/Column/VacuumRow/VacuumBar
@onready var world_prompt: Control = $WorldPrompt
@onready var world_prompt_panel: PanelContainer = $WorldPrompt/Panel
@onready var job_startprompt: Label = $WorldPrompt/Panel/Margin/Label
@onready var job_finished_banner: PanelContainer = $JobCompleteBanner
@onready var text_box: Control = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/TextMargin/Column/DialogueLabel
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_body: Label = $HelpPanel/Margin/Column/Body
@onready var help_subtext: Label = $HelpPanel/Margin/Column/Subtext

@export var show_job_progress: bool = false

var conversation_active := false
var _help_dismissed := false
var _dialogue_cache: Dictionary = {}
var _lines: Array = []
var _line_index: int = 0
var _block_id: StringName = &""

func _ready():
	yard_hud.visible = show_job_progress
	job_finished_banner.visible = false
	help_panel.visible = false
	text_box.visible = false
	text_box.gui_input.connect(_on_dialogue_gui_input)

func _input(event: InputEvent) -> void:
	if help_panel.visible and event.is_action_pressed("dismiss_help"):
		hide_help()
		get_viewport().set_input_as_handled()
		return
	if not conversation_active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance_line()

func begin_yard(job_data: JobData) -> void:
	yard_hud.visible = show_job_progress
	var name = TOOL_NAMES.get(job_data.yard_tool_id, "")
	tool_label.text = name
	vacuum_row.visible = job_data.yard_tool_id == 3
	set_vacuum_fill(-1.0)
	_help_dismissed = false
	if job_data.show_vacuum_help:
		call_deferred("show_vacuum_help")

func set_vacuum_fill(ratio: float) -> void:
	if not vacuum_row.visible:
		return
	if ratio < 0.0:
		vacuum_bar.value = 0.0
		return
	vacuum_bar.value = ratio * 100.0

func show_vacuum_help() -> void:
	if _help_dismissed:
		return
	help_body.text = "The vacuum can take leaves in it's storage with left click but once it's full it stops working! You need to spew them out the garden with right click to empty the storage."
	help_subtext.text = "press H to hide this notification"
	help_panel.visible = true
	help_panel.move_to_front()

func hide_help() -> void:
	help_panel.visible = false
	_help_dismissed = true

func show_job_complete_banner() -> void:
	job_finished_banner.visible = true

func hide_job_complete_banner() -> void:
	job_finished_banner.visible = false

func job_progress(progress):
	job_pgbar.value = progress
	progress_value.text = str(int(progress)) + "%"

func jobstart_prompt(visibility : bool, pos : Vector2):
	world_prompt.visible = visibility
	if not visibility:
		return
	world_prompt_panel.reset_size()
	world_prompt.size = world_prompt_panel.size
	world_prompt.position = pos - Vector2(world_prompt.size.x * 0.5, world_prompt.size.y)

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

func _on_dialogue_gui_input(event: InputEvent) -> void:
	if not conversation_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		text_box.accept_event()
		_advance_line()

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
