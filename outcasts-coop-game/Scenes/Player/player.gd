#CURRENTLY A BUG WHERE IF A PLAYER BREAKS SOMETHING BEFORE THE OTHER PLAYER JOINS,
#THEN THE JOINING PLAYERS MAP IS WRONG AND CAN BREAK THINGS, AND THE HOST CAN't PICK
#UP STUFF
class_name Player
extends CharacterBody2D

#tools
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

@onready var camera = $Camera2D

var player_direction: Vector2

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
	else:
		camera.enabled = false
