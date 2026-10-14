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
var _tools: Node

const CHEAT_PUSH_STRENGTH := 900.0

func _ready():
	starting_leaves = _count_leaves()
	exit.monitoring = false
	var player := find_child("Player", true, false)
	if player:
		_tools = player.find_child("Tools", true, false)
	if GameManager.current_job is JobData:
		ui.begin_yard(GameManager.current_job as JobData)

func _process(_delta: float) -> void:
	if _tools == null:
		return
	ui.set_vacuum_fill(_tools.get_vacuum_storage_ratio())

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_push_leaves"):
		return
	_cheat_push_leaves()
	get_viewport().set_input_as_handled()

func _cheat_push_leaves() -> void:
	var direction := Vector2.RIGHT
	var origin := global_position
	for node in find_children("*", "", true, false):
		if not node is Leaf:
			continue
		if node.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		node.receive_gust(origin, direction, CHEAT_PUSH_STRENGTH)

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
	leaves_cleared += 1
	if starting_leaves > 0:
		percent_oc = snapped(float(leaves_cleared) / float(starting_leaves), 0.01)
	ui.job_progress(minf(percent_oc * 100.0, 100.0))
	if job_status:
		return
	if percent_oc >= job_goal:
		job_status = true
		job_finished()
		
func job_finished() -> void:
	ui.show_job_complete_banner()
	exit.monitoring = true
	if GameManager.current_job is JobData:
		var data := GameManager.current_job as JobData
		if data.dialogue_file != "" and data.completion_dialogue_block != &"":
			ui.start_conversation(data.dialogue_file, data.completion_dialogue_block)

func _on_exit_body_entered(body: Node2D) -> void:
	_leave_through_exit(body)

func _leave_through_exit(body: Node) -> void:
	if _leaving or not job_status or not body is PlayerBase:
		return
	_leaving = true
	ui.hide_job_complete_banner()
	ui.cancel_conversation()
	ui.hide_help()
	GameManager.leave_job.call_deferred()
