extends Node

var players_id: Dictionary[int, PlayerData] = {}
var npc_id: Dictionary[int, PlayerData] = {}

var WB_id_self: int

@onready var SimulationRender = get_node("../SimulationRender")

var socket = WebSocketPeer.new()

func _ready():
	socket.connect_to_url("0.0.0.0:9999")

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
					SimulationRender.add_player(packet.decode_u8(1))
				Shared.Code.PLAYER_JOIN_SELF:
					WB_id_self = packet.decode_u32(2)
					print("Receiving client server id: ", WB_id_self)
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
		set_process(false) # Stop processing.

func send_movement_request(encoded_movement: int):
	var packet: PackedByteArray
	packet.resize(2)
	packet[0] = Shared.Code.PLAYER_MOVEMENT
	packet[1] = encoded_movement
	#print("Sending encoded movement: ", packet)
	socket.put_packet(packet)
