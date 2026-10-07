extends Node

var players_id: Dictionary[int, PlayerData] = {}
var npc_id: Dictionary[int, PlayerData] = {}

var Client_player = null
@onready var Network_client_id = $"../NetworkManager"
@onready var GraphicsRender = get_node("../GraphicsRender")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func receive_world_update(payload: PackedByteArray):
	#print("Received world update packet. ")
	var buf := StreamPeerBuffer.new()
	buf.data_array = payload
	buf.seek(3)
	var players_count := buf.get_u16()
	var npcs_count := buf.get_u16()
	#print("data: ", payload)
	for i in players_count:
		var id := buf.get_u8()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		print("  player ", id, " @ ", Vector2(x, y))
		if id == Network_client_id.WB_id_self:
			if Client_player == null:
				print("Client player not loaded yet")
				continue
			Client_player.client_position.x = x
			Client_player.client_position.y = y
			continue
		if not players_id.has(id):
			#print("Player id: ",id ," not in player list. Adding them.")
			continue
		GraphicsRender.update_players_position_graphical(id, x, y)
	for i in npcs_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		#print("  npc ", id, " @ ", Vector2(x, y))
	#print(players_id.keys())

func add_player(id: int, nickname: String):
	var new_player = PlayerData.new(Vector2.ZERO)
	players_id[id] = new_player
	
func remove_player():
	pass
	
func add_npc(id: int):
	var new_npc = PlayerData.new(Vector2.ZERO)
	npc_id[id] = new_npc
