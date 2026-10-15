extends Node

signal root_changed(root: Control)

var _root: Control
var movement_locked := false


func get_root() -> Control:
	return _root


func register_root(node: Control) -> void:
	_root = node
	root_changed.emit(node)


func unregister_root(node: Control) -> void:
	if _root == node:
		_root = null
		movement_locked = false


func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
