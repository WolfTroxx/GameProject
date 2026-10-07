extends Node

var players_id: Dictionary[int, PlayerData] = {}
var npc_id: Dictionary[int, PlayerData] = {}

var WB_id_self: int = -1

@onready var SimulationRender = get_node("../SimulationRender")
@onready var player_gui = get_node("../VBoxContainer")
@onready var GraphicsRender = get_node("../GraphicsRender")

var socket = WebSocketPeer.new()

func _ready():
	set_process(false)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet: PackedByteArray = socket.get_packet()
			#print("Packet received of size: ", packet.size())
			match packet[0]:
				
				Shared.Code.WORLD_UPDATE:
					SimulationRender.receive_world_update(packet)
					
				Shared.Code.NPC_JOIN:
					SimulationRender.add_npc(packet.decode_u8(1))
					
				Shared.Code.PLAYER_JOIN:
					if WB_id_self == -1:
						return
					var id = packet.decode_u8(1)
					var nickname: String = packet.duplicate().slice(2).get_string_from_ascii()
					print("Updating existing/new player. id: ", id)
					SimulationRender.add_player(id, nickname)
					GraphicsRender.Spawn_Player(id, nickname)
					
				Shared.Code.PLAYER_JOIN_SELF:
					WB_id_self = packet.decode_u8(1)
					print("Receiving client server id: ", WB_id_self)
					GraphicsRender.Spawn_Player(packet.decode_u8(1), "")
				Shared.Code.PLAYER_CONFIRM_USERNAME:
					packet.slice(1)
					var username: String = packet.get_string_from_ascii()
					print("Receiving self server username: ", username)
					GraphicsRender.update_player_nickname(username)
				Shared.Code.PLAYER_LEAVE:
					pass
					
				Shared.Code.PLAYER_SHOOT:
					pass
					
				_:
					print("Unknown opcode: ", packet[0])
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		 # Stop processing.

func send_movement_request(encoded_movement: int):
	var packet: PackedByteArray
	packet.resize(2)
	packet[0] = Shared.Code.PLAYER_MOVEMENT
	packet[1] = encoded_movement
	#print("Sending encoded movement: ", packet)
	socket.put_packet(packet)

func connect_to_server():
	socket.connect_to_url("wss://blackballsgame.duckdns.org/ws")
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		player_gui._player_disconnected()
		print("Player Disconnect.")
		return
	if state == WebSocketPeer.STATE_CONNECTING:
		player_gui._player_connecting()
		set_process(true)
		print("Server connecting")

func spawn_player(username: String):
	var packet: PackedByteArray
	packet.resize(1)
	packet[0] = Shared.Code.PLAYER_JOIN_WORLD
	packet.append_array(username.to_ascii_buffer())
	print("Requesting player spawn")
	socket.put_packet(packet)
