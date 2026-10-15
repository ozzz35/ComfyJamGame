class_name JobData
extends Resource

@export var is_tutorial: bool = false
@export_range(1, 4) var job_number: int = 1
@export_range(1, 4) var yard_tool_id: int = 1
@export var show_vacuum_help: bool = false
@export var offer_dialogue_block: StringName = &"job1_before"
@export_file("*.json") var dialogue_file: String = "res://dialogue/game_dialogue.json"
@export var completion_dialogue_block: StringName = &""
@export var yard_scene: PackedScene
@export_file("*.tscn") var street_scene: String = "res://scenes/main/main.tscn"
@export var return_marker: StringName = &"oldman_job_return"
