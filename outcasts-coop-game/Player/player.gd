extends CharacterBody2D

const SPEED: float = 500

func _ready() -> void:
	add_to_group("players")


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		velocity = Input.get_vector("Left", "Right", "Up", "Down") * SPEED
	move_and_slide()
