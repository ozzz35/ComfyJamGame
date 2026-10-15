class_name DialogueFocus
extends RefCounted

const NPC_NODE_NAMES := {
	"gilbert": &"OldNPC",
	"jane": &"FarmerNPC",
	"butcher": &"ButcherNPC",
	"ghost": &"Ghost",
}


static func global_position(root: Node, focus_id: String, player: Node2D = null) -> Vector2:
	if focus_id.is_empty():
		return Vector2.ZERO
	if focus_id == "player" and player != null:
		return player.global_position
	if focus_id == "gilbert":
		var yard_gilbert := root.find_child("GilbertFinale", true, false) as Node2D
		if yard_gilbert != null:
			return yard_gilbert.global_position
	var node_name: StringName = NPC_NODE_NAMES.get(focus_id, &"")
	if node_name == &"":
		return Vector2.ZERO
	var node := root.find_child(String(node_name), true, false) as Node2D
	if node == null:
		return Vector2.ZERO
	return node.global_position
