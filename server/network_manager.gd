extends Node



var connected_players_id: Dictionary[int, ConnectedPlayer] = {}
var WB_id_player_id: Dictionary[int, int] = {}
var system_player_id: = 0
@onready var Simulator = get_node("../Simulator")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var server_peer = WebSocketMultiplayerPeer.new()
	var error = server_peer.create_server(9999)
	if error != OK:
		print("Connection failed")
	else:
		print("Server open")
	multiplayer.multiplayer_peer = server_peer
	server_peer.peer_connected.connect(_on_peer_connected)
	server_peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.peer_packet.connect(_on_peer_packet)
	Simulator.world_snapshot_ready.connect(snapshot_update)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_peer_connected(new_id: int):
	var multiplayer_peer = multiplayer.multiplayer_peer
	var player := ConnectedPlayer.new(multiplayer_peer.get_peer(new_id))
	player.ip_address = multiplayer_peer.get_peer_address(new_id)
	player.WS_id = new_id
	WB_id_player_id[new_id] = system_player_id
	connected_players_id[system_player_id] = player
	Simulator.new_player_join(system_player_id, new_id, player)
	print("New player: ", new_id, " IP Address: ", player.ip_address, "System id: ", system_player_id)
	system_player_id += 1
	
func _on_peer_disconnected(disconnect_id: int):
	print("Player disconnected. (id: ", disconnect_id, ")")
	var existed = connected_players_id.erase(WB_id_player_id[disconnect_id])
	WB_id_player_id.erase(disconnect_id)
	Simulator.player_leave(system_player_id, disconnect_id)
	if existed:
		print("Deleted connected player. (id: ", disconnect_id, ")")

func _on_peer_packet(id: int, packet: PackedByteArray):
	match packet[0]:
		Opcode.Code.PLAYER_MOVEMENT:
			Simulator.player_movement_request(id, packet)

func snapshot_update(packet: PackedByteArray):
	var buffer := PackedByteArray()
	buffer.resize(packet.size() + 1)
	buffer[0] = Opcode.Code.WORLD_UPDATE
	for i in packet.size():
		buffer[1 + i] = packet[i]
	broadcast(buffer)
	print("World update of size: ", buffer.size(), " Op code: ", buffer[0])
	receive_world_update(buffer)

func receive_world_update(payload: PackedByteArray):
	var buf := StreamPeerBuffer.new()
	buf.data_array = payload
	buf.seek(3)
	var players_count := buf.get_u16()
	var npcs_count := buf.get_u16()
	#print("players=", players_count, " npcs=", npcs_count)
	#print("data: ", payload)
	for i in players_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		#print("  player ", id, " @ ", Vector2(x, y))
	for i in npcs_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		#print("  npc ", id, " @ ", Vector2(x, y))

func broadcast(payload: PackedByteArray):
	for id in connected_players_id:
		var player: ConnectedPlayer = connected_players_id[id]
		if not player.world_loaded:
			continue
		if player.websocket == null:
			print("Error: WebSocketPeer nonexistent.")
			continue
		if player.websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
			print("Error: WebSocketPeer Closed/Non-responding")
			continue
		player.websocket.put_packet(payload)
		print(payload)

func update_new_player_join(id: int, WB_id: int):
	var buffer := StreamPeerBuffer.new()
	buffer.put_u8(Opcode.Code.PLAYER_JOIN)
	buffer.put_u8(id)
	broadcast(buffer.data_array)
	buffer.put_u32(WB_id)
	buffer.seek(0)
	buffer.put_u8(Opcode.Code.PLAYER_JOIN_SELF)
	connected_players_id[id].websocket.put_packet(buffer.data_array)

func update_player_leave(id: int):
	var buffer := StreamPeerBuffer.new()
	buffer.put_u8(Opcode.Code.PLAYER_LEAVE)
	buffer.put_u8(id)
	broadcast(buffer.data_array)
