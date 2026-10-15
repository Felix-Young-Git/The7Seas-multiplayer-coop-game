extends Node2D

#packed scenes
@export var player_scene : PackedScene
@export var enemy_scene : PackedScene
@export var tilemap : PackedScene

@onready var ui = $UI

signal join_result(ok: bool)

func _ready() -> void:
	ui.set_state(ui.UIState.Menu)

	# Wait for EOS login before the buttons do anything
	if not EosNetwork.EosSetup:
		await EosNetwork.logged_in

	#Connect signals and functions
	$UI.host_pressed.connect(_on_host_pressed)
	$UI.join_pressed.connect(_on_join_pressed)
	$UI.spawn_enemy_pressed.connect(_on_spawn_enemy_pressed)

	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)

#BUTTON PRESSES-------------------------------------------------------------------
#create host (creates an EOS lobby instead of an ENet server)
func _on_host_pressed() -> void:
	var room_code = ui.get_host_IP_input() # reuse the text box as a room code
	var ok = await EosNetwork.create_lobby(room_code)
	if not ok:
		print("Failed to create lobby")
		return

	multiplayer.peer_connected.connect(_add_player)
	ui.set_state(ui.UIState.Host)
	_create_tilemap()
	_add_player(multiplayer.get_unique_id())

#join an existing EOS lobby
func _on_join_pressed() -> void:
	var ok = await EosNetwork.search_lobbies(ui.get_join_IP_input())
	if not ok:
		print("No lobby found")
		return

	# If neither success nor failure arrives in 15s, treat it as a failure
	var timer := get_tree().create_timer(15.0)
	timer.timeout.connect(_on_join_timeout)

	var connected = await join_result

	if timer.timeout.is_connected(_on_join_timeout):
		timer.timeout.disconnect(_on_join_timeout)
	if connected:
		ui.set_state(ui.UIState.Join)

func _on_join_timeout() -> void:
	print("Join timed out")
	_connected_fail()
#--------------------------------------------------------------------------------------------


#ADDING STUFF TO THE WORLD-----------------------------------------------------------------
#create player
func _add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)

#Spawning enemies
func _on_spawn_enemy_pressed(id = 1) -> void:
	if multiplayer.is_server():
		var enemy = enemy_scene.instantiate()
		add_child(enemy, true)

func _create_tilemap():
	if multiplayer.is_server():
		var map_instance = tilemap.instantiate()
		add_child(map_instance, true)
#--------------------------------------------------------------------------------------------


#CONNECTIONS----------------------------------------------------------------------------
func _connected_ok():
	print("Connected to server!")
	join_result.emit(true)

func _connected_fail():
	print("Failed to connect!")
	join_result.emit(false)
	await EosNetwork.exit_game()

func _peer_connected(id):
	print("Peer connected: ", id)

func _server_disconnected():
	print("Disconnected from server!")
	await EosNetwork.exit_game()
	get_tree().change_scene_to_file("res://Scenes/screens/game.tscn")
#--------------------------------------------------------------------------------------------
