extends Control

@onready var bg : ColorRect = $ColorRect
var alpha : float = 0
var speed : float = 0.5
var intro_lines : Array
@onready var _lines: Array[Label] = [
	$LineContainer/line0,
	$LineContainer/line1,
	$LineContainer/line2,
	$LineContainer/line3,
]
@onready var linecontainer: VBoxContainer = $LineContainer

func _ready():
	var path := DialogueLibrary.DEFAULT_PATH
	var file_text := FileAccess.get_file_as_string(path)
	var root = JSON.parse_string(file_text)
	bg.modulate.a = 0
	for i in _lines.size():
		_lines[i].modulate.a = 0
	
	if root is Dictionary and root.has("intro"):
		intro_lines = DialogueLibrary.normalize_block_lines(root["intro"])
	else:
		push_warning("Intro - could not load game_dialogue.json intro")
	for i in _lines.size():
		_lines[i].text = str(intro_lines[i]["text"])
	
func _process(delta):
	pass
	
func start() -> void:
	Audio.stop_music()
	visible = true
	bg.color = Color(0, 0, 0, 1)
	bg.modulate = Color(1, 1, 1, 0)
	
	var tween := create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 1.6)
	tween.finished.connect(_on_fade_in_finished)

func _on_fade_in_finished() -> void:
	var count := mini(_lines.size(), intro_lines.size())
	for i in count:
		_lines[i].modulate = Color(1, 1, 1, 0)
		var line_tween := create_tween()
		line_tween.tween_property(_lines[i], "modulate:a", 1.0, 1.5)
		await line_tween.finished
		await get_tree().create_timer(0.8).timeout

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(linecontainer, "modulate:a", 0.0, 0.5)
	fade_out.tween_property(bg, "modulate:a", 1.0, 0.5)
	await fade_out.finished
	GameManager.hub_fade_in_on_load = true
	GameManager.greet_gilbert_on_hub_load = true
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
