extends Node

@onready var rake := $Rake
@onready var broom := $Broom
@onready var vacuum := $LeafVacuum
@onready var blower := $LeafBlower
var last_tool : Sprite2D

func _ready():
	init()
	call_deferred("equip_yard_tool")

func init():
	rake.visible = false
	broom.visible = false
	vacuum.visible = false
	blower.visible = false
	rake.process_mode = Node.PROCESS_MODE_DISABLED
	broom.process_mode = Node.PROCESS_MODE_DISABLED
	vacuum.process_mode = Node.PROCESS_MODE_DISABLED
	blower.process_mode = Node.PROCESS_MODE_DISABLED

func equip_yard_tool() -> void:
	if not GameManager.in_job:
		return
	match GameManager.yard_tool_id():
		GameTools.BROOM: equip(broom)
		GameTools.RAKE: equip(rake)
		GameTools.VACUUM: equip(vacuum)
		GameTools.BLOWER: equip(blower)

func get_vacuum_storage_ratio() -> float:
	if vacuum.process_mode == Node.PROCESS_MODE_DISABLED:
		return -1.0
	if vacuum.vacuum_capacity <= 0:
		return 0.0
	return float(vacuum.vacuum_stored) / float(vacuum.vacuum_capacity)

func equip(tool : Sprite2D):
	if last_tool != null:
		last_tool.visible = false
		last_tool.process_mode = Node.PROCESS_MODE_DISABLED
	tool.visible = true
	tool.process_mode = Node.PROCESS_MODE_INHERIT
	last_tool = tool
