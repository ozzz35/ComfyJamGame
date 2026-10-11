extends TileMapLayer

@export var covered_alpha : float = 0.3
@export var fade_speed : float = 5.0

@onready var player : Node2D = get_parent().get_node_or_null("Actors/Player")

var sprites : Array[Sprite2D] = []
var areas : Array[Area2D] = []
var alphas : Array[float] = []

func _ready() -> void:
	var cells := get_used_cells()
	for cell in cells:
		var sprite := _make_sprite(cell)
		sprites.append(sprite)
		areas.append(_make_area(sprite))
		alphas.append(1.0)
		erase_cell(cell)
	_update_fade(1.0)

func _process(delta: float) -> void:
	_update_fade(delta)

func _make_sprite(cell: Vector2i) -> Sprite2D:
	var source := tile_set.get_source(get_cell_source_id(cell)) as TileSetAtlasSource
	var tile_data := get_cell_tile_data(cell)
	var region := source.get_tile_texture_region(get_cell_atlas_coords(cell))
	var sprite := Sprite2D.new()
	sprite.texture = source.texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = map_to_local(cell) - Vector2(region.size) * 0.5 - Vector2(tile_data.texture_origin)
	add_child(sprite)
	return sprite

func _make_area(sprite: Sprite2D) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	area.monitorable = false
	var cover_size := Vector2(sprite.region_rect.size) - Vector2(16, 8)
	var shape := RectangleShape2D.new()
	shape.size = cover_size
	var shape_node := CollisionShape2D.new()
	shape_node.shape = shape
	shape_node.position = Vector2(8, 0) + cover_size * 0.5
	area.add_child(shape_node)
	sprite.add_child(area)
	return area

func _update_fade(delta: float) -> void:
	for i in sprites.size():
		var covered := false
		if player and _under(sprites[i], player.global_position):
			covered = true
		elif areas[i].has_overlapping_areas():
			covered = true
		var target := covered_alpha if covered else 1.0
		alphas[i] = move_toward(alphas[i], target, fade_speed * delta)
		sprites[i].modulate.a = alphas[i]

func _under(sprite: Sprite2D, point: Vector2) -> bool:
	var local_point := sprite.to_local(point)
	var tree_rect := Rect2(Vector2(8, 0), Vector2(sprite.region_rect.size) - Vector2(16, 8))
	return tree_rect.has_point(local_point)
