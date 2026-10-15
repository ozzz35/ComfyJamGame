class_name DialogueLibrary
extends RefCounted

const DEFAULT_PATH := "res://dialogue/game_dialogue.json"


static func resolve_path(path: String) -> String:
	if path.is_empty():
		return DEFAULT_PATH
	return path


static func get_block_lines(file_root: Dictionary, block_id: StringName) -> Array:
	if file_root.is_empty():
		return []
	if file_root.has("blocks"):
		var blocks: Dictionary = file_root.blocks
		var key := String(block_id)
		if blocks.has(key):
			return normalize_block_lines(blocks[key])
	if file_root.has(block_id):
		return normalize_block_lines(file_root[block_id])
	return []


static func normalize_block_lines(block_data: Variant) -> Array:
	if block_data is Array:
		return _normalize_line_array(block_data)
	if block_data is Dictionary and block_data.has("lines"):
		return _normalize_line_array(block_data.lines)
	return []


static func _normalize_line_array(raw: Array) -> Array:
	var out: Array = []
	for entry in raw:
		if entry is String:
			out.append({"speaker": "narrator", "text": entry})
		elif entry is Dictionary:
			out.append(entry.duplicate(true))
	return out
