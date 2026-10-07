extends Node

var players_id: Dictionary[int, PlayerData] = {}
##Dictionary with key WebSocket id and entry system id
var WB_id_player_id: Dictionary[int, int] = {}
var npc_id: Dictionary[int, PlayerData] = {}

var npc_list_id: = 0

var snapshot_countdown : int = 0

@export var sibling_node: Node
@onready var NetworkManager = get_node("../NetworkManager")

signal world_snapshot_ready(packet: PackedByteArray)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var npc1 = PlayerData.new(Vector2(100, 100)) 
	#npc1.movement_direction = Vector2(2.4, 4.3)
	#npc_list_id += 1
	#npc_id[npc_list_id] = npc1
	#print("npc id: ", npc_list_id, " added")
	#npc1 = PlayerData.new(Vector2(15, 10))
	#npc1.position = Vector2(50, 50)
	#npc1.movement_direction = Vector2(5.7, 2.9)
	#npc_list_id += 1
	#npc_id[npc_list_id] = npc1
	#print("npc id: ", npc_list_id, " added")
# Called every frame. 'delta' is the elapsed time since the previous frame.
	pass
func _process(_delta: float) -> void:
	pass

func simulation_tick(_delta: float, _tick: int):
	for id in players_id:
		var player = players_id[id]
		if player.change_of_direction || player.movement_direction != Vector2.ZERO:
			#print("Player id: ", id, "Changing direction: ", player.change_of_direction, "Direction: ", player.movement_direction)
			player.position += PlayerData.player_movement_speed * player.movement_direction
			player.recent_movement = true
			if player.movement_direction == Vector2.ZERO:
				player.recent_movement = false
		if player.previous_position != player.position:
			player.recent_movement = true
			player.previous_position = player.position
			
	for id in npc_id:
		var npc = npc_id[id]
		if npc.change_of_direction:
			npc.position += PlayerData.npc_movement_speed * npc.movement_direction
		if npc.previous_position != npc.position:
			npc.recent_movement = true
			npc.previous_position = npc.position
	#print("Tick: ", tick, " Elapsed time: ", delta)
	#print("Snapshot countdown: ", snapshot_countdown)
	if snapshot_countdown == 0:
		#print("Building snapshot")
		snapshot_build()
		snapshot_countdown = 2
	snapshot_countdown -= 1

func new_player_join(system_id: int, id: int):
	var player = PlayerData.new(Vector2.ZERO)
	player.world_loaded = true
	WB_id_player_id[id] = system_id
	players_id[system_id] = player
	NetworkManager.update_new_player_join(system_id, id)
	print("Added player. (id: ", id, " )")

func player_leave(system_id: int, leave_id: int):
	players_id.erase(WB_id_player_id[leave_id])
	WB_id_player_id.erase(leave_id)
	NetworkManager.update_player_leave(system_id)
	print("Deleted player. (id: ", leave_id, ")")

func snapshot_build():
	var snapshot := StreamPeerBuffer.new()
	snapshot.put_u16(0)
	snapshot.put_u16(0)
	snapshot.put_u16(0)

	var player_update_count:= 0
	for id in players_id:
		var player = players_id[id]
		if not player.recent_movement:
			#print("Player not moving, skipping its update.")
			continue
		#print("Player id: ", id, "Changes direction, sending update")
		snapshot.put_u8(id)
		var qx := clampi(int(player.position.x * 10.0), -32768, 32767)
		var qy := clampi(int(player.position.y * 10.0), -32768, 32767)
		snapshot.put_16(qx)
		snapshot.put_16(qy)
		player_update_count += 1
	#print("Player count: ", player_update_count)
	var npc_update_count:= 0
	for id in npc_id:
		var npc = npc_id[id]
		if not npc.recent_movement:
			continue
		snapshot.put_u32(id)
		var qx := clampi(int(npc.position.x * 10.0), -32768, 32767)
		var qy := clampi(int(npc.position.y * 10.0), -32768, 32767)
		snapshot.put_16(qx)
		snapshot.put_16(qy)
		npc_update_count += 1
		
	snapshot.seek(2)
	snapshot.put_u16(player_update_count)
	snapshot.seek(4)
	snapshot.put_u16(npc_update_count)
	
	world_snapshot_ready.emit(snapshot.data_array)

func packet_payload(player_id: int, player_packet: PackedByteArray):
	pass

func player_movement_request(player_id: int, packet: int):
	var player = players_id[WB_id_player_id[player_id]]
	var new_player_direction: Vector2
	#var packet_bin: int = packet.decode_u8(0)
	var x = (packet&1) - ((packet>>1)&1)
	var y = ((packet>>2)&1) - ((packet>>3)&1)
	if ( x && y ):
		x *= 0.7071
		y *= 0.7071
	new_player_direction = Vector2(x, y)
	#print("Player directions: ")
	#print(player.movement_direction)
	#print(new_player_direction)
	if player.movement_direction == new_player_direction:
		player.change_of_direction = false
		print("Player:change_of_direction = ", player.change_of_direction)
		return
	player.movement_direction = new_player_direction
	player.change_of_direction = true
