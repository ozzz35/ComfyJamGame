extends Node2D

@onready var garden_area: Polygon2D = $GardenArea
@onready var ui = $Ui/UiRoot
@onready var exit : Area2D = $Exit

var percent_oc : float = 0.0
var starting_leaves : int = 0
var job_status : bool = false
var leaves_cleared : int = 0

@export var job_goal : float = 0.98


var _leaving := false

func _ready():
	starting_leaves = _count_leaves()
	exit.monitoring = false
	
func _count_leaves() -> int:
	var total : int = 0
	for node in find_children("*", "", true, false):
		if node.has_method("receive_gust"):
			total += 1
	return total

func contains_world_point(world_position: Vector2) -> bool:
	var local_point := garden_area.to_local(world_position)
	return Geometry2D.is_point_in_polygon(local_point, garden_area.polygon)
	
func leaf_removed():
	if job_status == true:
		return
	leaves_cleared += 1 
	print("Leaves cleared: ", leaves_cleared, "\n Completion: ", percent_oc)
	percent_oc = snapped(float(leaves_cleared) / float(starting_leaves), 0.01)
	ui.job_progress(percent_oc * 100)
	if percent_oc >= job_goal:
		job_status = true
		job_finished()
		GameManager.edit_money(100)
		ui.update_ui()
		print("Finished!")
		
func job_finished() -> void:
	ui.job_finishedprompt.visible = true
	exit.monitoring = true


func _on_exit_body_entered(body: Node2D) -> void:
	_leave_through_exit(body)

func _leave_through_exit(body: Node) -> void:
	if _leaving or not job_status or not body is PlayerBase:
		return
	_leaving = true
	ui.job_finishedprompt.visible = false
	GameManager.leave_job.call_deferred()
