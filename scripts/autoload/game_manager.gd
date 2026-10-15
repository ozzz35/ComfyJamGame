extends Node

var current_job : Resource
var in_job : bool = false
var tutorial_done : bool = false
var job1_done : bool = false
var job2_done : bool = false
var job3_done : bool = false
var job4_done : bool = false

func start_job(job):
	in_job = true
	if job == null:
		return
	current_job = job
	get_tree().change_scene_to_packed(job.yard_scene)

func yard_tool_id() -> int:
	if current_job is JobData:
		return (current_job as JobData).yard_tool_id
	return 0

func tool_unlocked(tool_id: int) -> bool:
	return in_job and tool_id == yard_tool_id()

func leave_job() -> void:
	if current_job is JobData:
		var data := current_job as JobData
		if data.is_tutorial:
			tutorial_done = true
		else:
			_set_job_done(data.job_number)
	in_job = false
	var destination := "res://scenes/main/main.tscn"
	var marker_name := "oldman_job_return"
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

func is_job_done(job_number: int) -> bool:
	match job_number:
		1: return job1_done
		2: return job2_done
		3: return job3_done
		4: return job4_done
	return false

func can_offer_job(job: JobData) -> bool:
	if job == null:
		return false
	if job.is_tutorial:
		return not tutorial_done
	if not tutorial_done:
		return false
	if is_job_done(job.job_number):
		return false
	for n in range(1, job.job_number):
		if not is_job_done(n):
			return false
	return true

func _set_job_done(job_number: int) -> void:
	match job_number:
		1: job1_done = true
		2: job2_done = true
		3: job3_done = true
		4: job4_done = true
