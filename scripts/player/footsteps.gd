extends AudioStreamPlayer2D

@export var grass_steps : Array[AudioStream] 

var last_index : int = -1
var stride : float = 60 # How quickly the step sound repeats
var distance : float = 0
var player : CharacterBody2D
var last_speed : float = 0
var was_moving := false
var was_in_leaves := false
var near_padding : float = 18

@onready var leaf_check_area : Area2D = $"../LeafCheckArea"
@onready var feets : Marker2D = $"../Feets"
@onready var moving : bool = $"../MovementComp".input_vector != Vector2.ZERO

func _ready():
	player = get_parent()

func _physics_process(delta: float) -> void:
	moving = $"../MovementComp".input_vector != Vector2.ZERO
	var in_leaves := _near_leaf_pile()
	if moving and not was_moving:
		distance = 0.0
		was_moving = true
		was_in_leaves = in_leaves
		terrain_check()
		return
	was_moving = moving
	if not moving:
		distance = 0.0
		was_in_leaves = in_leaves
		return
	if in_leaves and not was_in_leaves:
		distance = 0.0
		was_in_leaves = true
		terrain_check()
		return
	was_in_leaves = in_leaves
	distance += player.velocity.length() * delta
	if distance < stride:
		return
	distance -= stride
	terrain_check()


func terrain_check():
	## WIP for later
	# If terrain = grass:
	# Play grass walking sound aswell
	##
	if _near_leaf_pile():
		play_step() # Play leaf/grass step when we'll have it
	else:
		return
		play_step() # Play normal step array when we'll have it



func _near_leaf_pile() -> bool:
	var hits = leaf_check_area.get_overlapping_areas()
	return not hits.is_empty()


func play_step() -> void:
	if grass_steps.is_empty():
		return
	var index := randi_range(0, grass_steps.size() - 1)
	while grass_steps.size() > 1 and index == last_index:
		index = randi_range(0, grass_steps.size() - 1)
	stream = grass_steps[index]
	pitch_scale = randf_range(0.94, 1.06)
	play()
	last_index = index
