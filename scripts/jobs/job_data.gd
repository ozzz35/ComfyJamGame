class_name JobData
extends Resource

@export_range(1, 4) var job_number: int = 1
@export_file("*.json") var dialogue_file: String = ""
@export var completion_dialogue_block: StringName = &""
@export var yard_scene: PackedScene
@export_file("*.tscn") var street_scene: String = "res://scenes/main/main.tscn"
@export var return_marker: StringName = &"job1"
