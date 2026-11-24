extends Node2D

var has_orb := false

func _ready() -> void:
	_apply()

func set_has_orb(value: bool) -> void:
	has_orb = value
	if is_node_ready():
		_apply()

func _apply() -> void:
	$MissingOrb.visible = not has_orb
	$WithOrb.visible = has_orb
