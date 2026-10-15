extends Node

const BROOM := 1
const RAKE := 2
const VACUUM := 3
const BLOWER := 4

const _DISPLAY_NAMES := {
	BROOM: "Broom",
	RAKE: "Rake",
	VACUUM: "Leaf vacuum",
	BLOWER: "Leaf blower",
}


func display_name(tool_id: int) -> String:
	return _DISPLAY_NAMES.get(tool_id, "")


func is_vacuum(tool_id: int) -> bool:
	return tool_id == VACUUM
