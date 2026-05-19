extends CharacterBody2D

const SPEED: float = 500

@onready var camera = $Camera2D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
	else:
		camera.enabled = false

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		velocity = Input.get_vector("Left", "Right", "Up", "Down") * SPEED
		move_and_slide()
