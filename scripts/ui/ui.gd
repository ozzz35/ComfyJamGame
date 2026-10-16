extends Control

signal conversation_finished(block_id: StringName)
signal dialogue_line(line: Dictionary)
signal dialogue_action(action: StringName)
signal hub_fade_in_finished

const PORTRAITS := {
	"gilbert": preload("res://assets/art/ui/portraits/gilbert_portrait.png"),
	"jane": preload("res://assets/art/ui/portraits/jane_portrait.png"),
	"butcher": preload("res://assets/art/ui/portraits/butcher_portrait.png"),
	"ghost": preload("res://assets/art/ui/portraits/ghost_portrait.png"),
}

const SPEAKER_FOCUS_IDS := ["gilbert", "jane", "butcher", "ghost", "player"]

const BUTCHER_MUSIC_FADE := 1.0

const BUTCHER_DIALOGUE_BLOCKS: Array[StringName] = [
	&"job2_before",
	&"job2_before_blocked",
	&"butcher_about",
	&"job2_yard_start",
	&"job2_after",
	&"job2_street_after_done",
]

const STOP_MUSIC_DIALOGUE_BLOCKS: Array[StringName] = [
	&"job3_finale",
	&"job3_epilogue",
]

@onready var yard_hud: Control = $YardHud
@onready var job_pgbar: TextureProgressBar = $YardHud/HudPanel/Margin/Column/JobProgress
@onready var progress_value: Label = $YardHud/HudPanel/Margin/Column/ProgressRow/ProgressValue
@onready var tool_label: Label = $YardHud/HudPanel/Margin/Column/ToolLabel
@onready var vacuum_row: HBoxContainer = $YardHud/HudPanel/Margin/Column/VacuumRow
@onready var vacuum_bar: TextureProgressBar = $YardHud/HudPanel/Margin/Column/VacuumRow/VacuumBar
@onready var world_prompt: Control = $WorldPrompt
@onready var world_prompt_panel: PanelContainer = $WorldPrompt/Panel
@onready var job_startprompt: Label = $WorldPrompt/Panel/Margin/Label
@onready var job_finished_banner: PanelContainer = $JobCompleteBanner
@onready var text_box: Control = $DialoguePanel
@onready var portrait: TextureRect = $DialoguePanel/Portrait
@onready var dialogue_label: Label = $DialoguePanel/TextMargin/Column/DialogueLabel
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_body: Label = $HelpPanel/Margin/Column/Body
@onready var help_subtext: Label = $HelpPanel/Margin/Column/Subtext
@onready var credits_overlay: TextureRect = $CreditsOverlay
@onready var credits_label: Label = $CreditsOverlay/CreditsMargin/CreditsLabel
@onready var options_overlay: Control = $OptionsOverlay
@onready var hub_fade_overlay: ColorRect = $HubFadeOverlay
@onready var talk_choice_panel: PanelContainer = $TalkChoicePanel
@onready var talk_choice_work_button: Button = $TalkChoicePanel/Margin/Column/WorkButton
@onready var talk_choice_about_button: Button = $TalkChoicePanel/Margin/Column/AboutButton

@export var show_job_progress: bool = false
@export var hub_fade_in_duration: float = 1.2

var _hub_fade_in_running := false

var conversation_active := false
var talk_choice_active := false
var _help_dismissed := false
var _dialogue_cache: Dictionary = {}
var _lines: Array = []
var _line_index: int = 0
var _block_id: StringName = &""
var _credits_lines: PackedStringArray = PackedStringArray()
var _credits_scroll := 0.0
var _talk_choice_callback: Callable

func _ready() -> void:
	GameUI.register_root(self)
	if not tree_exiting.is_connected(_on_tree_exiting):
		tree_exiting.connect(_on_tree_exiting)
	yard_hud.visible = show_job_progress
	job_finished_banner.visible = false
	help_panel.visible = false
	text_box.visible = false
	credits_overlay.visible = false
	portrait.visible = false
	text_box.gui_input.connect(_on_dialogue_gui_input)
	talk_choice_work_button.pressed.connect(_on_talk_choice_work_pressed)
	talk_choice_about_button.pressed.connect(_on_talk_choice_about_pressed)
	talk_choice_panel.visible = false
	var root := _load_dialogue_file(DialogueLibrary.DEFAULT_PATH)
	if root.has("credits"):
		_credits_lines = PackedStringArray(root.credits)
	_start_hub_fade_in_if_needed()

func is_hub_fade_in_running() -> bool:
	return _hub_fade_in_running

func _start_hub_fade_in_if_needed() -> void:
	if not GameManager.hub_fade_in_on_load:
		hub_fade_overlay.visible = false
		return
	GameManager.hub_fade_in_on_load = false
	_hub_fade_in_running = true
	hub_fade_overlay.visible = true
	hub_fade_overlay.modulate = Color(1, 1, 1, 1)
	GameUI.set_movement_locked(true)
	var tween := create_tween()
	tween.tween_property(hub_fade_overlay, "modulate:a", 0.0, hub_fade_in_duration)
	tween.finished.connect(_on_hub_fade_in_finished)

func _on_hub_fade_in_finished() -> void:
	_hub_fade_in_running = false
	hub_fade_overlay.visible = false
	GameUI.set_movement_locked(false)
	hub_fade_in_finished.emit()

func _process(delta: float) -> void:
	if not credits_overlay.visible:
		return
	_credits_scroll += delta * 42.0
	credits_label.position.y = credits_overlay.size.y - _credits_scroll
	if _credits_scroll > credits_label.size.y + credits_overlay.size.y + 80.0:
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_tree_exiting() -> void:
	if options_overlay.is_open():
		get_tree().paused = false
	GameUI.unregister_root(self)

func _unhandled_input(event: InputEvent) -> void:
	if talk_choice_active and event.is_action_pressed("ui_cancel"):
		_finish_talk_choice(&"")
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if credits_overlay.visible:
		return
	if options_overlay.is_open():
		options_overlay.close()
	else:
		options_overlay.open()
	get_viewport().set_input_as_handled()

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
	tool_label.text = GameTools.display_name(job_data.yard_tool_id)
	vacuum_row.visible = GameTools.is_vacuum(job_data.yard_tool_id)
	set_vacuum_fill(-1.0)
	_help_dismissed = false
	if job_data.show_vacuum_help:
		call_deferred("show_vacuum_help")
	var yard_block := _yard_start_block(job_data)
	if yard_block != &"":
		var path := DialogueLibrary.resolve_path(job_data.dialogue_file)
		call_deferred("start_conversation", path, yard_block)

func _yard_start_block(job_data: JobData) -> StringName:
	if job_data.is_tutorial:
		return &"tutorial_yard_start"
	match job_data.job_number:
		1:
			return &"job1_yard_start"
		2:
			return &"job2_yard_start"
		3:
			return &"job3_gilbert_yard_start"
	return &""

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

func job_progress(progress) -> void:
	job_pgbar.value = progress
	progress_value.text = str(int(progress)) + "%"

func jobstart_prompt(visibility: bool, pos: Vector2) -> void:
	world_prompt.visible = visibility
	if not visibility:
		return
	world_prompt_panel.reset_size()
	world_prompt.size = world_prompt_panel.size
	world_prompt.position = pos - Vector2(world_prompt.size.x * 0.5, world_prompt.size.y)

func talk_prompt(visibility: bool, pos: Vector2) -> void:
	if visibility:
		job_startprompt.text = "Press E to talk"
	jobstart_prompt(visibility, pos)

## Callback receives &"work", &"about", or &"" when the player backs out.
func show_talk_choice(callback: Callable) -> void:
	_talk_choice_callback = callback
	talk_choice_active = true
	talk_choice_panel.visible = true
	talk_choice_panel.move_to_front()
	GameUI.set_movement_locked(true)

func _finish_talk_choice(choice: StringName) -> void:
	if not talk_choice_active:
		return
	talk_choice_active = false
	talk_choice_panel.visible = false
	var callback := _talk_choice_callback
	_talk_choice_callback = Callable()
	if choice.is_empty():
		GameUI.set_movement_locked(false)
	if callback.is_valid():
		callback.call(choice)

func _on_talk_choice_work_pressed() -> void:
	_finish_talk_choice(&"work")

func _on_talk_choice_about_pressed() -> void:
	_finish_talk_choice(&"about")

func start_conversation(path: String, block_id: StringName) -> bool:
	var file_root := _load_dialogue_file(path)
	var lines := DialogueLibrary.get_block_lines(file_root, block_id)
	if lines.is_empty():
		return false
	_lines = lines
	_block_id = block_id
	_line_index = 0
	conversation_active = true
	GameUI.set_movement_locked(true)
	text_box.visible = true
	_apply_dialogue_music(block_id)
	_show_line(_lines[0])
	return true

func show_credits(extra_lines: PackedStringArray = PackedStringArray()) -> void:
	cancel_conversation()
	var combined := _credits_lines.duplicate()
	for line in extra_lines:
		combined.append(line)
	credits_label.text = "\n\n".join(combined)
	credits_label.reset_size()
	_credits_scroll = 0.0
	credits_label.position.y = credits_overlay.size.y
	credits_overlay.visible = true
	credits_overlay.move_to_front()

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
	_show_line(_lines[_line_index])

func _show_line(line: Variant) -> void:
	var entry := _enrich_line(line if line is Dictionary else {"text": str(line)})
	dialogue_label.text = str(entry.get("text", ""))
	_apply_portrait(entry)
	dialogue_line.emit(entry)
	var action := str(entry.get("action", ""))
	if not action.is_empty():
		dialogue_action.emit(StringName(action))

func _enrich_line(raw: Dictionary) -> Dictionary:
	var entry := raw.duplicate()
	if str(entry.get("focus", "")).is_empty():
		var speaker := str(entry.get("speaker", ""))
		if speaker in SPEAKER_FOCUS_IDS:
			entry["focus"] = speaker
	return entry

func _apply_portrait(line: Dictionary) -> void:
	var portrait_key := str(line.get("portrait", line.get("speaker", "")))
	if PORTRAITS.has(portrait_key):
		portrait.texture = PORTRAITS[portrait_key]
		portrait.visible = true
	else:
		portrait.visible = false

func cancel_conversation() -> void:
	var ended_block := _block_id
	conversation_active = false
	GameUI.set_movement_locked(false)
	text_box.visible = false
	dialogue_label.text = ""
	portrait.visible = false
	_lines.clear()
	_block_id = &""
	_line_index = 0
	_release_dialogue_music(ended_block)

func _close_conversation() -> void:
	var finished_id := _block_id
	cancel_conversation()
	conversation_finished.emit(finished_id)

func _apply_dialogue_music(block_id: StringName) -> void:
	if block_id in STOP_MUSIC_DIALOGUE_BLOCKS:
		Audio.stop_music(1.5)
	elif block_id in BUTCHER_DIALOGUE_BLOCKS:
		Audio.crossfade_music_volume(-80.0, BUTCHER_MUSIC_FADE)
		Audio.begin_remnant_vanish_audio()

func _release_dialogue_music(block_id: StringName) -> void:
	if block_id in BUTCHER_DIALOGUE_BLOCKS:
		Audio.end_remnant_vanish_audio()
		Audio.crossfade_music_volume(0.0, BUTCHER_MUSIC_FADE)

func _load_dialogue_file(path: String) -> Dictionary:
	var resolved := DialogueLibrary.resolve_path(path)
	if _dialogue_cache.has(resolved):
		return _dialogue_cache[resolved]
	var text := FileAccess.get_file_as_string(resolved)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_dialogue_cache[resolved] = parsed
		return parsed
	return {}
