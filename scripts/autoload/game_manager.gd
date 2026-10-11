extends Node

var money : int = 0
var current_job : Resource

func edit_money(amount):
	money += amount

func start_job(job):
	if job == null:
		return
	current_job = job
	get_tree().change_scene_to_packed(job.yard_scene)
	
func leave_job() -> void:
	var destination := "res://scenes/main/main.tscn"
	var marker_name := "job1"
	if current_job != null:
		if String(current_job.street_scene) != "":
			destination = String(current_job.street_scene)
		if String(current_job.return_marker) != "":
			marker_name = String(current_job.return_marker)
	get_tree().change_scene_to_file(destination)
	for _attempt in 5:
		await get_tree().process_frame
		var street := get_tree().current_scene
		if street == null or street.scene_file_path != destination:
			continue
		var marker := street.find_child(marker_name, true, false) as Node2D
		var player := street.find_child("Player", true, false) as Node2D
		if marker == null or player == null:
			continue
		player.global_position = marker.global_position
		player.reset_physics_interpolation()
		return
