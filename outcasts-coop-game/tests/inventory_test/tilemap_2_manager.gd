extends Node2D

@onready var water_layer = $Water
@onready var tree_layer = $Trees
@onready var rock_layer = $Rocks
@export var collectable_log_scene : PackedScene
@export var collectable_rock_scene : PackedScene

#connect the signals
func _ready() -> void:
	add_to_group("tilemap")
	connect_tree_signals()
	connect_rock_signals()
	tree_layer.child_entered_tree.connect(_on_child_entered_tree)
	rock_layer.child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(child: Node) -> void:
	if child.has_signal("tree_damaged"):
		# Avoid duplicate connections just in case
		if not child.tree_damaged.is_connected(on_tree_damaged):
			child.tree_damaged.connect(on_tree_damaged)

	if child.has_signal("rock_damaged"):
		# Avoid duplicate connections just in case
		if not child.rock_damaged.is_connected(on_rock_damaged):
			child.rock_damaged.connect(on_rock_damaged)


func connect_tree_signals():
	for child in tree_layer.get_children():
		if child.has_signal("tree_damaged"):
			child.tree_damaged.connect(on_tree_damaged)

func connect_rock_signals():
	for child in rock_layer.get_children():
		if child.has_signal("rock_damaged"):
			child.rock_damaged.connect(on_rock_damaged)

#apply damage to trees
func on_tree_damaged(cell: Vector2i, hit_damage: int):
	if multiplayer.is_server():
		server_apply_tree_damage(cell, hit_damage)
	else:
		server_apply_tree_damage.rpc(cell, hit_damage)

@rpc("any_peer", "call_local", "reliable")
func server_apply_tree_damage(cell: Vector2i, hit_damage: int) -> void:
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

#add the small log
func add_small_log(cell: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	
	var collectable_log_instance = collectable_log_scene.instantiate() as Node2D
	var world_pos = tree_layer.to_global(tree_layer.map_to_local(cell))
	collectable_log_instance.global_position = world_pos
	collectable_log_instance.name = "small_log_" + str(cell.x) + "_" + str(cell.y)
	get_parent().add_child(collectable_log_instance, true)


#rock
func on_rock_damaged(cell: Vector2i, hit_damage: int):
	if multiplayer.is_server():
		server_apply_rock_damage(cell, hit_damage)
	else:
		server_apply_rock_damage.rpc(cell, hit_damage)

@rpc("any_peer", "call_local", "reliable")
func server_apply_rock_damage(cell: Vector2i, hit_damage: int) -> void:
	if multiplayer.is_server():
		var rock = find_rock_at_cell(cell)
		if rock:
			rock.damage_component.apply_damage(hit_damage)
			if rock.damage_component.is_dead():
				on_rock_destroyed(rock)

func find_rock_at_cell(cell: Vector2i) -> Node:
	for child in rock_layer.get_children():
		if child.has_method("get_cell_from_self"):
			if child.get_cell_from_self() == cell:
				return child
	return null

func on_rock_destroyed(rock: Node):
	var cell = rock.get_cell_from_self()
	sync_destroy_rock.rpc(cell)

@rpc("call_local")
func sync_destroy_rock(cell: Vector2i):
	add_small_rock(cell)
	rock_layer.erase_cell(cell)

func add_small_rock(cell: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	
	var collectable_rock_instance = collectable_rock_scene.instantiate() as Node2D
	var world_pos = rock_layer.to_global(rock_layer.map_to_local(cell))
	collectable_rock_instance.global_position = world_pos
	collectable_rock_instance.name = "small_rock_" + str(cell.x) + "_" + str(cell.y)
	get_parent().add_child(collectable_rock_instance, true)


func is_water_tile(world_pos: Vector2) -> bool:
	var local_pos = water_layer.to_local(world_pos)
	var cell = water_layer.local_to_map(local_pos)
	var tile_data = water_layer.get_cell_tile_data(cell)
	return tile_data and tile_data.get_custom_data("is_water")
