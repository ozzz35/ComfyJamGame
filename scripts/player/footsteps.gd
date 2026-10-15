extends AudioStreamPlayer2D

@export var grass_steps : Array[AudioStream] 
@export var dirt_steps : Array[AudioStream]
@export var road_steps : Array[AudioStream]

var last_index : int = -1
var stride : float = 60 # How quickly the step sound repeats
var distance : float = 0
var player : CharacterBody2D
var was_moving := false
var was_in_leaves := false

var audiomap : TileMapLayer
@onready var leaf_check_area : Area2D = $"../LeafCheckArea"
@onready var feets : Marker2D = $"../Feets"
@onready var moving : bool = $"../MovementComp".input_vector != Vector2.ZERO

func _ready():
	player = get_parent()
	audiomap = _find_audio_map()


func _find_audio_map() -> TileMapLayer:
	var node: Node = self
	while node:
		var found := node.find_child("AudioMapLayer", true, false)
		if found is TileMapLayer:
			return found
		node = node.get_parent()
	return null


func _physics_process(delta: float) -> void:
	moving = $"../MovementComp".input_vector != Vector2.ZERO
	var in_leaves := _near_leaf_pile()
	var started_moving := moving and not was_moving
	var leaves_changed := in_leaves != was_in_leaves
	was_moving = moving
	was_in_leaves = in_leaves
	if not moving:
		distance = 0.0
		return
	if started_moving or leaves_changed:
		distance = 0.0
		terrain_check()
		return
	distance += player.velocity.length() * delta
	if distance < stride:
		return
	distance -= stride
	terrain_check()


func terrain_check():
	if _near_leaf_pile():
		play_step(grass_steps)
		return
	if audiomap == null:
		return
	var feet_pos = audiomap.to_local(feets.global_position)
	var cell_pos = audiomap.local_to_map(feet_pos)
	var ground_type = audiomap.get_cell_tile_data(cell_pos)
	if ground_type == null:
		return
	if ground_type.get_custom_data("road"):
		play_step(road_steps)
	elif ground_type.get_custom_data("dirt"):
		play_step(dirt_steps)
	elif ground_type.get_custom_data("grass"):
		play_step(grass_steps)

func _near_leaf_pile() -> bool:
	var hits = leaf_check_area.get_overlapping_areas()
	return not hits.is_empty()


func play_step(ground_type) -> void:
	if ground_type.is_empty():
		return
	var index := randi_range(0, ground_type.size() - 1)
	while ground_type.size() > 1 and index == last_index:
		index = randi_range(0, ground_type.size() - 1)
	stream = ground_type[index]
	pitch_scale = randf_range(0.94, 1.06)
	play()
	last_index = index
