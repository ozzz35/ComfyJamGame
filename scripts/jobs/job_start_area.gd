@tool
extends Node2D

@export var job: JobData
@export_range(8, 600, 1) var range: int = 20:
	set(value):
		range = maxi(value, 1)
		_apply_range()

@onready var area: Area2D = $JobArea2D
@onready var shape_node: CollisionShape2D = $JobArea2D/CollisionShape2D
@onready var ui := $"../../../UI/UiRoot"

var above_player : Vector2 
var player_here := false
var player : PlayerBase

func _ready() -> void:
	_apply_range()
	if Engine.is_editor_hint():
		return
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _process(delta):
	if player_here == false:
		return
	ui.jobstart_prompt(true, get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16)))

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not player_here:
		return
	if not event.is_action_pressed("interact"):
		return
	if job == null:
		return
	get_viewport().set_input_as_handled()
	GameManager.start_job(job)


func _apply_range() -> void:
	if not is_node_ready():
		return
	var circle := shape_node.shape as CircleShape2D
	if circle:
		circle.radius = range
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		player = body
		above_player = get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -16))
		player_here = true
		ui.jobstart_prompt(true, above_player)
	
func _on_body_exited(body: Node2D) -> void:
	if body is PlayerBase:
		player_here = false
		ui.jobstart_prompt(false, above_player)
		
