extends Node2D

@onready var tree_layer = $Objects
@export var collectable_log_scene : PackedScene

#connect the signals
func _ready() -> void:
	connect_tree_signals()
	tree_layer.child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(child: Node) -> void:
	if child.has_signal("tree_damaged"):
		# Avoid duplicate connections just in case
		if not child.tree_damaged.is_connected(on_tree_damaged):
			child.tree_damaged.connect(on_tree_damaged)

func connect_tree_signals():
	for child in tree_layer.get_children():
		if child.has_signal("tree_damaged"):
			child.tree_damaged.connect(on_tree_damaged)


#apply damage
func on_tree_damaged(cell: Vector2i, hit_damage: int):
	if multiplayer.is_server():
		server_apply_damage(cell, hit_damage)
	else:
		server_apply_damage.rpc(cell, hit_damage)

@rpc("any_peer", "call_local", "reliable")
func server_apply_damage(cell: Vector2i, hit_damage: int) -> void:
	if multiplayer.is_server():
		var tree = find_tree_at_cell(cell)
		if tree:
			tree.damage_component.apply_damage(hit_damage)
			if tree.damage_component.is_dead():
				on_tree_destroyed(tree)

func find_tree_at_cell(cell: Vector2i) -> Node:
	for child in tree_layer.get_children():
		if child.has_method("get_cell_from_self"):
			if child.get_cell_from_self() == cell:
				return child
	return null


#destroy tree
func on_tree_destroyed(tree: Node):
	var cell = tree.get_cell_from_self()
	sync_destroy_tree.rpc(cell)


@rpc("call_local")
func sync_destroy_tree(cell: Vector2i):
	add_small_log(cell)
	tree_layer.erase_cell(cell)


#add the small rock
func add_small_log(cell: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	
	var collectable_log_instance = collectable_log_scene.instantiate() as Node2D
	var world_pos = tree_layer.to_global(tree_layer.map_to_local(cell))
	collectable_log_instance.global_position = world_pos
	collectable_log_instance.name = "small_log_" + str(cell.x) + "_" + str(cell.y)
	get_parent().add_child(collectable_log_instance, true)
