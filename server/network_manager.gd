extends Node



var connected_players_id: Dictionary[int, ConnectedPlayer] = {}
var WB_id_player_id: Dictionary[int, int] = {}
var system_player_id: = 0
@onready var Simulator = get_node("../Simulator")

var world_snapshots_sent: int = 0
var snapshot_sizes: Array[int] = []

var TCP_Server = TCPServer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var error = TCP_Server.listen(9999, "127.0.0.1")
	
	#var server_peer = WebSocketMultiplayerPeer.new()
	#var error = server_peer.create_server(9999)
	if error != OK:
		print("Connection failed")
	else:
		print("Server open")
		
	#multiplayer.multiplayer_peer = server_peer
	#server_peer.peer_connected.connect(_on_peer_connected)
	#server_peer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.peer_packet.connect(_on_peer_packet)
	Simulator.world_snapshot_ready.connect(snapshot_update)

# Called every frame. 'delta' is the elapsed time since the previous frame.

var pending_websockets: Array[WebSocketPeer] = []
var WebSocket_player_id: int = 0

func _process(delta: float) -> void:
	if world_snapshots_sent > 100:
		var stats = calculate_snapshot_stats()
		print("World snapshot updates stats: ")
		print(stats, " Time interval: ", delta)
	if TCP_Server.is_listening():
		while TCP_Server.is_connection_available():
			var websocket:= WebSocketPeer.new()
			websocket.accept_stream(TCP_Server.take_connection())
			pending_websockets.append(websocket)
	
		for pending_websocket in pending_websockets.duplicate():
			pending_websocket.poll()
			match pending_websocket.get_ready_state():
				WebSocketPeer.STATE_OPEN:
					pending_websockets.erase(pending_websocket)
					var player := ConnectedPlayer.new(pending_websocket)
					player.ip_address = pending_websocket.get_connected_host()
					player.WS_id = WebSocket_player_id
					WB_id_player_id[WebSocket_player_id] = system_player_id
					connected_players_id[system_player_id] = player
					#
					print("New player: ", WebSocket_player_id, " IP Address: ", player.ip_address, "System id: ", system_player_id)
					system_player_id += 1
					WebSocket_player_id += 1
				WebSocketPeer.STATE_CLOSED:
					pending_websockets.erase(pending_websocket)
	
		for player_id in connected_players_id.keys():
			var player_websocket = connected_players_id[player_id].websocket
			var player_WB_id = connected_players_id[player_id].WS_id
			player_websocket.poll()
			match player_websocket.get_ready_state():
				WebSocketPeer.STATE_OPEN:
					while player_websocket.get_available_packet_count() > 0:
						_handle_peer_packet(player_id, player_websocket.get_packet())
				WebSocketPeer.STATE_CLOSING:
					pass
				WebSocketPeer.STATE_CLOSED:
					print("Player disconnected. (id: ", player_id, ")")
					if connected_players_id[player_id].world_loaded == true:
						Simulator.player_leave(WB_id_player_id[player_id], player_WB_id)
					var existed = connected_players_id.erase(WB_id_player_id[player_id])
					WB_id_player_id.erase(player_WB_id)
					if existed:
						print("Deleted connected player. (id: ", player_id, ")")

func _handle_peer_packet(id: int, packet: PackedByteArray):
	if packet.size() < 1:
		print("Error, broken package? Peer id: ", id)
		return
	var player_requesting_WS_id: = connected_players_id[id].WS_id
	match packet[0]:
		
		Shared.Code.PLAYER_MOVEMENT:
			#print("Receiving player movement update.")
			if packet.size() < 2:
				print("Incomplete movement packet from player id: ", id, " Packet: ", packet, " Packet size: ", packet.size())
			if not connected_players_id[id].world_loaded:
				print("Error, player not loaded in world and requesting movement. id: ", id)
				return
			Simulator.player_movement_request(id, packet[1])
			
		Shared.Code.PLAYER_JOIN_WORLD:
			var error = packet.size()
			if error > 17:
				print("Error, username or packet too big: ", error)
				return
			packet.slice(1)
			var username_confirm_packet: PackedByteArray
			username_confirm_packet = packet.duplicate()
			print("New player username: ", packet)
			connected_players_id[id].username = packet.get_string_from_ascii()
			connected_players_id[id].world_loaded = true
			Simulator.new_player_join(id, player_requesting_WS_id)
			username_confirm_packet[0] = Shared.Code.PLAYER_CONFIRM_USERNAME
			connected_players_id[id].websocket.put_packet(username_confirm_packet)
			
		_:
			print("Unknown Opcode: ", packet[0], " From player id: ", id)



#func _on_peer_connected(new_id: int):
	#var multiplayer_peer = multiplayer.multiplayer_peer
	#var player := ConnectedPlayer.new(multiplayer_peer.get_peer(new_id))
	#player.ip_address = multiplayer_peer.get_peer_address(new_id)
	#player.WS_id = new_id
	#WB_id_player_id[new_id] = system_player_id
	#connected_players_id[system_player_id] = player
	#Simulator.new_player_join(system_player_id, new_id, player)
	#print("New player: ", new_id, " IP Address: ", player.ip_address, "System id: ", system_player_id)
	#system_player_id += 1
	#
#func _on_peer_disconnected(disconnect_id: int):
	#print("Player disconnected. (id: ", disconnect_id, ")")
	#var existed = connected_players_id.erase(WB_id_player_id[disconnect_id])
	#WB_id_player_id.erase(disconnect_id)
	#Simulator.player_leave(system_player_id, disconnect_id)
	#if existed:
		#print("Deleted connected player. (id: ", disconnect_id, ")")



func snapshot_update(packet: PackedByteArray):
	var buffer := PackedByteArray()
	buffer.resize(packet.size() + 1)
	buffer[0] = Shared.Code.WORLD_UPDATE
	var packetsize = packet.size()
	for i in packetsize:
		buffer[1 + i] = packet[i]
	#print("World update of size: ", buffer.size(), " Op code: ", buffer[0])
	broadcast(buffer)
	
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
		var id := buf.get_u8()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		#print("  player ", id, " @ ", Vector2(x, y))
	for i in npcs_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		#print("  npc ", id, " @ ", Vector2(x, y))

func broadcast(payload: PackedByteArray):
	var payloadsize = payload.size()
	for id in connected_players_id:
		world_snapshots_sent += 1
		snapshot_sizes.append(payloadsize) 
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
		#print(payload)

func update_new_player_join(id: int, WB_id: int):
	print("new player join")
	var buffer: PackedByteArray
	buffer.resize(2)
	buffer.encode_u8(0, Shared.Code.PLAYER_JOIN)
	buffer.encode_u8(1, id)
	buffer.append_array(connected_players_id[id].username.to_ascii_buffer())
	broadcast(buffer)
	buffer.resize(2)
	buffer.encode_u8(1, WB_id)
	buffer.encode_u8(0, Shared.Code.PLAYER_JOIN_SELF)
	connected_players_id[id].websocket.put_packet(buffer)
	update_newer_player(id)
	

func update_newer_player(id: int):
	var buffer: PackedByteArray
	buffer.resize(2)
	buffer.encode_u8(0, Shared.Code.PLAYER_JOIN)
	for i in connected_players_id:
		if i == id:
			continue
		buffer.encode_u8(1, i)
		buffer.append_array(connected_players_id[i].username.to_ascii_buffer())
		connected_players_id[id].websocket.put_packet(buffer)
		print("Performing update of existing player id: ", i, "to player id: ", id)
	
	
func update_player_leave(id: int):
	var buffer := StreamPeerBuffer.new()
	buffer.put_u8(Shared.Code.PLAYER_LEAVE)
	buffer.put_u8(id)
	broadcast(buffer.data_array)

func calculate_snapshot_stats() -> Dictionary:
	if snapshot_sizes.is_empty():
		return {}

	var min_size := snapshot_sizes[0]
	var max_size := snapshot_sizes[0]
	var total := 0

	for size in snapshot_sizes:
		total += size

		if size < min_size:
			min_size = size

		if size > max_size:
			max_size = size

	var average := float(total) / snapshot_sizes.size()
	snapshot_sizes.clear()
	world_snapshots_sent = 0
	return {
		"count": snapshot_sizes.size(),
		"min": min_size,
		"max": max_size,
		"average": average,
		"total_bytes": total
	}
	
