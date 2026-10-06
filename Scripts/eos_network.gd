extends Node

signal logged_in()
signal player_connected(player_id)
signal player_disconnected(player_id)

var backend
var EosSetup := false

var peer:
	get:
		return backend.peer if backend else null

func _ready() -> void:
	get_tree().auto_accept_quit = false
	# load() at runtime so the web build never parses the EOS script
	var path := "res://Scripts/net_webrtc.gd" if OS.has_feature("web") else "res://Scripts/net_eos.gd"
	backend = load(path).new()
	backend.logged_in.connect(_on_backend_logged_in)
	backend.player_connected.connect(func(id): player_connected.emit(id))
	backend.player_disconnected.connect(func(id): player_disconnected.emit(id))
	add_child(backend)

func _on_backend_logged_in() -> void:
	EosSetup = true
	logged_in.emit()

func create_lobby(lobby_id = null, max_players = 8) -> bool:
	return await backend.create_lobby(lobby_id, max_players)

func search_lobbies(lobby_id = null) -> bool:
	return await backend.search_lobbies(lobby_id)

func lock_lobby() -> void:
	await backend.lock_lobby()

func exit_game() -> void:
	await backend.exit_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await exit_game()
		get_tree().quit()
