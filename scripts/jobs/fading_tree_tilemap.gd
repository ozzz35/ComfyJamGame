extends TileMapLayer

class TreeCover:
	var sprite: Sprite2D
	var area: Area2D
	var alpha: float = 1.0

@export var covered_alpha : float = 0.3
@export var fade_speed : float = 5.0

@onready var player : Node2D = get_parent().find_child("Player", true, false) as Node2D

var trees: Array[TreeCover] = []

func _ready() -> void:
	var sort_parent := get_parent()
	y_sort_enabled = sort_parent != null and sort_parent.y_sort_enabled
	var cells := get_used_cells()
	for cell in cells:
		var sprite := _make_sprite(cell)
		var tree := TreeCover.new()
		tree.sprite = sprite
		tree.area = _make_area(sprite)
		trees.append(tree)
		erase_cell(cell)
	_update_fade(1.0)

func _process(delta: float) -> void:
	_update_fade(delta)

func _make_sprite(cell: Vector2i) -> Sprite2D:
	var source := tile_set.get_source(get_cell_source_id(cell)) as TileSetAtlasSource
	var tile_data := get_cell_tile_data(cell)
	var region := source.get_tile_texture_region(get_cell_atlas_coords(cell))
	var ground := map_to_local(cell)
	var anchor := Node2D.new()
	anchor.position = ground
	add_child(anchor)
	var sprite := Sprite2D.new()
	sprite.texture = source.texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = -Vector2(region.size) * 0.5 - Vector2(tile_data.texture_origin)
	anchor.add_child(sprite)
	return sprite

func _cover_rect(sprite: Sprite2D) -> Rect2:
	return Rect2(Vector2(8, 0), Vector2(sprite.region_rect.size) - Vector2(16, 8))

func _make_area(sprite: Sprite2D) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	area.monitorable = false
	var cover := _cover_rect(sprite)
	var shape := RectangleShape2D.new()
	shape.size = cover.size
	var shape_node := CollisionShape2D.new()
	shape_node.shape = shape
	shape_node.position = cover.position + cover.size * 0.5
	area.add_child(shape_node)
	sprite.add_child(area)
	return area

func _update_fade(delta: float) -> void:
	for tree in trees:
		var covered := false
		if player and _under(tree.sprite, player.global_position):
			covered = true
		elif tree.area.has_overlapping_areas():
			covered = true
		var target := covered_alpha if covered else 1.0
		tree.alpha = move_toward(tree.alpha, target, fade_speed * delta)
		tree.sprite.modulate.a = tree.alpha

func _under(sprite: Sprite2D, point: Vector2) -> bool:
	return _cover_rect(sprite).has_point(sprite.to_local(point))
