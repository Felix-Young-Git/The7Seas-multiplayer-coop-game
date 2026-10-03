extends Node2D

signal logged_in()
signal player_connected(player_id)
signal player_disconnected(player_id)


@onready var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()

var local_user_id = ""
var is_server = false
var peer_user_ids = []

var EosSetup = false

var local_lobby: HLobby

func _ready() -> void:
	get_tree().auto_accept_quit = false
	#Initialize the SDK
	if not EosSetup:
		var init_opts = EOS.Platform.InitializeOptions.new()
		init_opts.product_name = "The7Seas" #Replace EosCredentials.PRODUCT_NAME with your actual PRODUCT_NAME from the EOS website
		init_opts.product_version = "b2bf6d4ad1d6443d9dfc4f51e5edcce3" #Replace EosCredentials.PRODUCT_ID with your actual PRODUCT_ID from the EOS website
	
		var init_results = EOS.Platform.PlatformInterface.initialize(init_opts)
		if init_results != EOS.Result.Success:
			printerr("Failed to initialize EOS SDK: " + EOS.result_str(init_results))
			return
	
		# Create EOS platform
		var create_opts = EOS.Platform.CreateOptions.new()
		create_opts.product_id = "b2bf6d4ad1d6443d9dfc4f51e5edcce3" #Replace EosCredentials.PRODUCT_ID with your actual PRODUCT_ID from the EOS website
		create_opts.sandbox_id = "9f09459bf57a4a3daf8a953542975d13" #Replace EosCredentials.SANDBOX_ID with your actual SANDBOX_ID from the EOS website
		create_opts.deployment_id = "1d5bc9dfff7c46c7a888cfcd7ed53503" #Replace EosCredentials.DEPLOYMENT_ID with your actual DEPLOYMENT_ID from the EOS website
		create_opts.client_id = "xyza7891OdAhhKTOTeZMCapl5kdJt4zR" #Replace EosCredentials.CLIENT_ID with your actual CLIENT_ID from the EOS website
		create_opts.client_secret = "x1QapzZY0GQ+6gW4FCH8rXprKyLigCaMm4a4Px4a/kY" #Replace EosCredentials.CLIENT_SECRET with your actual CLIENT_SECRET from the EOS website
		create_opts.encryption_key = "7820596134872609537184269058371462905738164290537184629053718224" #Replace EosCredentials.ENCRYPTION_KEY with your any string of 64 numbers
	
		var _create_results = 0
		_create_results = EOS.Platform.PlatformInterface.create(create_opts)
	
		EOS.get_instance().connect_interface_login_callback.connect(_on_connect_login_callback)
	
		peer.peer_connected.connect(_on_peer_connected)
		peer.peer_disconnected.connect(_on_peer_disconnected)
		
		await HAuth.login_anonymous_async("User")
		EosSetup = true
		
		logged_in.emit()
	else:
		peer.peer_connected.connect(_on_peer_connected)
		peer.peer_disconnected.connect(_on_peer_disconnected)
		logged_in.emit()
	
func exit_game():
	var lobby := local_lobby
	local_lobby = null
	is_server = false
	peer_user_ids.clear()

	if peer:
		peer.close()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null

	if lobby and lobby.is_valid():
		if lobby.is_owner():
			await lobby.destroy_async()
		else:
			await lobby.leave_async()
	
func _exit_tree() -> void:
	exit_game()

func _on_connect_login_callback(data: Dictionary) -> void:
	if not data.success:
		print("Login failed")
		EOS.print_result(data)
		return
		
	local_user_id = data.local_user_id
	HAuth.product_user_id = local_user_id
		
#LOBBY CREATION CODE
#-----------------------------------#
func create_lobby(lobby_id = null, max_players = 8):
	var create_opts := EOS.Lobby.CreateLobbyOptions.new()
	create_opts.bucket_id = _bucket_for(lobby_id)
	create_opts.max_lobby_members = max_players

	var new_lobby = await HLobbies.create_lobby_async(create_opts)
	if new_lobby == null:
		return false

	var result := peer.create_server("fthe7seas")
	if result != OK:
		return false

	multiplayer.multiplayer_peer = peer
	is_server = true
	local_lobby = new_lobby
	return true

func _bucket_for(code) -> String:
	var c := str(code).strip_edges() if code != null else ""
	return "The7Seas_" + c if c != "" else "The7Seas"

#LOBBY JOIN CODE
#---------------------------------------#
func search_lobbies(lobby_id = null) -> bool:
	# Search for public lobbies
	var bucket := _bucket_for(lobby_id)
	var lobbies = null
	for attempt in 6: # new lobbies can take a few seconds to become searchable
		lobbies = await HLobbies.search_by_bucket_id_async(bucket)
		if lobbies:
			break
		await get_tree().create_timer(1.0).timeout
	
	if not lobbies:
		return false

	# Join a lobby
	var lobby: HLobby = lobbies[0]
	await HLobbies.join_by_id_async(lobby.lobby_id)
	local_lobby = lobby
	
	var result := peer.create_client("fthe7seas", lobby.owner_product_user_id)
	if result != OK:
		return false
		
	multiplayer.multiplayer_peer = peer
	return true
	
func lock_lobby():
	if is_server and local_lobby:
		local_lobby.permission_level = EOS.Lobby.LobbyPermissionLevel.InviteOnly
		var success = await local_lobby.update_async()
		if success:
			print("Lobby locked (hidden from search)")
		else:
			print("Failed to lock lobby")
	
#GAME CODE
#-----------------------------------#
func _on_peer_connected(peer_id: int) -> void:
	peer_user_ids.append(peer_id)
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_user_ids.erase(peer_id)
	player_disconnected.emit(peer_id)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await exit_game()
		get_tree().quit()
