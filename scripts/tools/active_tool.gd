extends Node

@onready var rake := $Rake
@onready var broom := $Broom
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
	rake.process_mode = Node.PROCESS_MODE_DISABLED
	broom.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	if event.is_action_pressed("tool_1"):
		equip(broom)
	if event.is_action_pressed("tool_2"):
		equip(rake)
		
func equip(tool : Sprite2D):
	if last_tool != null:
		last_tool.visible = false
		last_tool.process_mode = Node.PROCESS_MODE_DISABLED
	tool.visible = true
	tool.process_mode = Node.PROCESS_MODE_INHERIT
	last_tool = tool
