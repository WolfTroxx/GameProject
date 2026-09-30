extends Node

var players_id: Dictionary[int, PlayerData] = {}
var npc_id: Dictionary[int, PlayerData] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func receive_world_update(payload: PackedByteArray):
	print("Received world update packet. ")
	var buf := StreamPeerBuffer.new()
	buf.data_array = payload
	buf.seek(3)
	var players_count := buf.get_u16()
	var npcs_count := buf.get_u16()
	#print("data: ", payload)
	for i in players_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		print("  player ", id, " @ ", Vector2(x, y))
	for i in npcs_count:
		var id := buf.get_u32()
		var x := buf.get_16() / 10.0
		var y := buf.get_16() / 10.0
		print("  npc ", id, " @ ", Vector2(x, y))

func add_player(id: int):
	var new_player = PlayerData.new(Vector2.ZERO)
	players_id[id] = new_player
func add_npc(id: int):
	var new_npc = PlayerData.new(Vector2.ZERO)
	npc_id[id] = new_npc
