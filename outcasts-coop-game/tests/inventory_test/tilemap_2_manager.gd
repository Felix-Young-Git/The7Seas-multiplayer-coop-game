extends Node2D

@onready var water_layer = $Water
@onready var tree_layer = $Trees
@onready var rock_layer = $Rocks
@onready var berry_layer = $Berries
@export var collectable_log_scene : PackedScene
@export var collectable_rock_scene : PackedScene
@export var collectable_heat_resist_berry : PackedScene

#connect the signals
func _ready() -> void:
	add_to_group("tilemap")
	connect_tree_signals()
	connect_rock_signals()
	connect_heat_resist_berry_signals()
	tree_layer.child_entered_tree.connect(_on_child_entered_tree)
	rock_layer.child_entered_tree.connect(_on_child_entered_tree)
	berry_layer.child_entered_tree.connect(_on_child_entered_tree)


func _on_child_entered_tree(child: Node) -> void:
	if child.has_signal("tree_damaged"):
		# Avoid duplicate connections just in case
		if not child.tree_damaged.is_connected(on_tree_damaged):
			child.tree_damaged.connect(on_tree_damaged)

	if child.has_signal("rock_damaged"):
		# Avoid duplicate connections just in case
		if not child.rock_damaged.is_connected(on_rock_damaged):
			child.rock_damaged.connect(on_rock_damaged)
	
	if child.has_signal("bush_picked"):
		if not child.bush_picked.is_connected(on_bush_picked):
			child.bush_picked.connect(on_bush_picked)

func connect_heat_resist_berry_signals():
	for child in berry_layer.get_children():
		if child.has_signal("bush_picked"):
			child.bush_picked.connect(on_bush_picked)

func on_bush_picked(cell: Vector2i):
	if multiplayer.is_server():
		server_apply_bush_picked(cell)
	else:
		server_apply_bush_picked.rpc(cell)

@rpc("any_peer", "call_local", "reliable")
func server_apply_bush_picked(cell: Vector2i) -> void:
	if multiplayer.is_server():
		var bush = find_bush_at_cell(cell)
		if bush:
			bush.update_bush_to_picked()
			sync_harvest_bush.rpc(cell)


func find_bush_at_cell(cell: Vector2i) -> Node:
	for child in berry_layer.get_children():
		if child.has_method("get_cell_from_self"):
			if child.get_cell_from_self() == cell:
				return child
	return null

@rpc("call_local")
func sync_harvest_bush(cell: Vector2i):
	add_heat_resist_berry(cell)
	berry_layer.erase_cell(cell)

func add_heat_resist_berry(cell : Vector2i):
	if not multiplayer.is_server():
		return
	
	var collectable_heat_resist_berry_instance = collectable_heat_resist_berry.instantiate() as Node2D
	var world_pos = berry_layer.to_global(berry_layer.map_to_local(cell))
	collectable_heat_resist_berry_instance.global_position = world_pos
	collectable_heat_resist_berry_instance.name = "heat_resist_berry_" + str(cell.x) + "_" + str(cell.y)
	get_parent().add_child(collectable_heat_resist_berry_instance, true)


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
