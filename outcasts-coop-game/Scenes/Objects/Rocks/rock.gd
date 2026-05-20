extends Sprite2D

@onready var hurt_component: HurtComponent = $hurt_component
@onready var damage_component: DamageComponent = $DamageComponent

@export var collectable_rock_scene : PackedScene

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)
	
	
func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	#extra stuff
	#material.set_shader_parameter("shake_intensity", 0.3)
	#await get_tree().create_timer(0.5).timeout
	#material.set_shader_parameter("shake_intensity", 0.0)
	
#remove the rock and put little rock
func on_max_damage_reached() -> void:
	call_deferred("add_small_rock_scene")
	queue_free()

#actually create the small rock
func add_small_rock_scene() -> void:
	#casts as node2d
	var collectable_rock_instance = collectable_rock_scene.instantiate() as Node2D
	#sets the collectable rock's position to the rock's position
	collectable_rock_instance.global_position = global_position
	get_parent().add_child(collectable_rock_instance)
