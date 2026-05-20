extends Sprite2D

@onready var hurt_component: HurtComponent = $hurt_component
@onready var damage_component: DamageComponent = $DamageComponent

@export var collectable_rock_scene : PackedScene

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)
	

#triggers when player hits with tool
func on_hurt(hit_damage: int) -> void:
	rpc_id(1, "server_apply_damage", hit_damage)

#only called by server
@rpc("any_peer", "call_local", "reliable")
func server_apply_damage(hit_damage: int) -> void:
	if multiplayer.is_server():
		damage_component.apply_damage(hit_damage)

#runs only on server because server is the only only calling apply_damage
func on_max_damage_reached() -> void:
	if multiplayer.is_server():
		rpc("sync_destruction")

#runs on serer and broadcasts to every connected client
@rpc("authority", "call_local", "reliable")
func sync_destruction() -> void:
	add_small_rock()
	queue_free()

#add the small rock
func add_small_rock() -> void:
	var collectable_rock_instance = collectable_rock_scene.instantiate() as Node2D
	collectable_rock_instance.global_position = global_position
	collectable_rock_instance.name = "small_rock" + name + "_" + str(Time.get_ticks_msec())
	get_parent().add_child(collectable_rock_instance)
