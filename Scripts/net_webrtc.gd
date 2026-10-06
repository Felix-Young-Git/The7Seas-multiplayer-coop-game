extends Node

signal logged_in()
signal player_connected(player_id)
signal player_disconnected(player_id)
signal _reply(msg)

const SIGNALING_URL := "wss://YOUR-RELAY.example.com" #THIS NEEDS TO CHANGE TO THE DEPLYED RELAY AND MUST BE wss://
const ICE := {"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]}

var peer: WebRTCMultiplayerPeer
var ws: WebSocketPeer
var is_server := false
var _ws_was_open := false

func _ready() -> void:
	multiplayer.connected_to_server.connect(_close_signaling)
	logged_in.emit()

func _process(_d: float) -> void:
	if ws == null:
		return
	ws.poll()
	var state := ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		_ws_was_open = true
		while ws.get_available_packet_count() > 0:
			var m = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if m is Dictionary:
				_handle(m)
	elif state == WebSocketPeer.STATE_CLOSED:
		ws = null
		_reply.emit({"type": "error", "reason": "closed"})

# --- lobby API (same signatures as net_eos.gd) ---
func create_lobby(room = null, max_players = 8) -> bool:
	if not await _connect_signaling():
		return false
	_send({"type": "host", "room": _room(room), "max": max_players})
	var r = await _reply
	if r.get("type") != "hosted":
		return false
	peer = WebRTCMultiplayerPeer.new()
	if peer.create_server() != OK:
		return false
	_wire(peer)
	multiplayer.multiplayer_peer = peer
	is_server = true
	return true

func search_lobbies(room = null) -> bool:
	if not await _connect_signaling():
		return false
	var r = {}
	for attempt in 6:
		if ws == null:
			return false
		_send({"type": "join", "room": _room(room)})
		r = await _reply
		if r.get("type") == "joined":
			break
		await get_tree().create_timer(1.0).timeout
	if r.get("type") != "joined":
		return false
	peer = WebRTCMultiplayerPeer.new()
	if peer.create_client(int(r.id)) != OK:
		return false
	_wire(peer)
	multiplayer.multiplayer_peer = peer
	_create_peer(1) # the host is always id 1
	return true

func lock_lobby() -> void:
	if is_server:
		_send({"type": "lock"})

func exit_game() -> void:
	is_server = false
	if peer:
		peer.close()
		peer = null
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	_close_signaling()

# --- internals ---
func _room(code) -> String:
	var c := str(code).strip_edges() if code != null else ""
	return c if c != "" else "default"

func _wire(p: WebRTCMultiplayerPeer) -> void:
	p.peer_connected.connect(func(id): player_connected.emit(id))
	p.peer_disconnected.connect(func(id): player_disconnected.emit(id))

func _connect_signaling() -> bool:
	_close_signaling()
	ws = WebSocketPeer.new()
	if ws.connect_to_url(SIGNALING_URL) != OK:
		ws = null
		return false
	var start := Time.get_ticks_msec()
	while ws != null and ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		if Time.get_ticks_msec() - start > 20000: # free hosts can cold-start slowly
			_close_signaling()
			return false
		await get_tree().process_frame
	return ws != null

func _close_signaling() -> void:
	if ws:
		ws.close()
		ws = null

func _send(d: Dictionary) -> void:
	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(d))

func _handle(m: Dictionary) -> void:
	match m.get("type"):
		"hosted", "joined", "error":
			_reply.emit(m)
		"peer_joined":
			_create_peer(int(m.id))
		"relay":
			var from := int(m.from)
			if peer == null or not peer.has_peer(from):
				return
			var conn = peer.get_peer(from).connection
			var p = m.payload
			match m.kind:
				"offer": conn.set_remote_description("offer", p.sdp)
				"answer": conn.set_remote_description("answer", p.sdp)
				"candidate": conn.add_ice_candidate(p.mid, int(p.index), p.sdp)

func _create_peer(id: int) -> void:
	var c := WebRTCPeerConnection.new()
	c.initialize(ICE)
	c.session_description_created.connect(_on_sdp.bind(id))
	c.ice_candidate_created.connect(_on_ice.bind(id))
	peer.add_peer(c, id)
	if id < peer.get_unique_id(): # joiners offer to the host, never the reverse
		c.create_offer()

func _on_sdp(type: String, sdp: String, id: int) -> void:
	if peer == null or not peer.has_peer(id):
		return
	peer.get_peer(id).connection.set_local_description(type, sdp)
	_send({"type": "relay", "to": id, "kind": type, "payload": {"sdp": sdp}})

func _on_ice(media: String, index: int, name: String, id: int) -> void:
	_send({"type": "relay", "to": id, "kind": "candidate",
		"payload": {"mid": media, "index": index, "sdp": name}})
