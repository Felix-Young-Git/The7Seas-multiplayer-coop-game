extends Sprite2D

@onready var hurt_component: HurtComponent = $hurt_component
@onready var damage_component: DamageComponent = $DamageComponent


signal tree_damaged(cell: Vector2i, hit_damage: int)

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	

#triggers when player hits with tool
func on_hurt(hit_damage: int) -> void:
	var tilemap = get_parent()
	var cell = tilemap.local_to_map(tilemap.to_local(global_position))
	tree_damaged.emit(cell, hit_damage)
	

func get_cell_from_self() -> Vector2i:
	var tilemap = get_parent()
	return tilemap.local_to_map(
		tilemap.to_local(global_position)
	)
