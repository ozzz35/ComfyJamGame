extends Node

@onready var rake := $Rake
@onready var broom := $Broom
@onready var vacuum := $LeafVacuum
@onready var blower := $LeafBlower
var last_tool : Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	init()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func init():
	rake.visible = false
	broom.visible = false
	vacuum.visible = false
	blower.visible = false
	rake.process_mode = Node.PROCESS_MODE_DISABLED
	broom.process_mode = Node.PROCESS_MODE_DISABLED
	vacuum.process_mode = Node.PROCESS_MODE_DISABLED
	blower.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	if GameManager.in_job == false:
		return
	if event.is_action_pressed("tool_1"):
		equip(broom)
	if event.is_action_pressed("tool_2"):
		if GameManager.has_rake:
			equip(rake)
	if event.is_action_pressed("tool_3"):
		if GameManager.has_vacuum:
			equip(vacuum)
	if event.is_action_pressed("tool_4"):
		if GameManager.has_blower:
			equip(blower)
	
func equip(tool : Sprite2D):
	if last_tool != null:
		last_tool.visible = false
		last_tool.process_mode = Node.PROCESS_MODE_DISABLED
	tool.visible = true
	tool.process_mode = Node.PROCESS_MODE_INHERIT
	last_tool = tool
