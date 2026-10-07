extends Node

@onready var SelfPlayerCharacter = preload("res://_Self_Player_Body.tscn")
@onready var SimulationRender = get_node("../SimulationRender")
@onready var PlayerCharacter = preload("res://Player_Body.tscn")

var self_is_spawned: bool = false
var players_id: Dictionary[int, CharacterBody2D] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Spawn_Player(id: int, nickname: String):
	if not self_is_spawned:
		var self_player = SelfPlayerCharacter.instantiate()
		var camera = Camera2D.new()
		self_player.add_child(camera)
		get_parent().add_child(self_player)
		SimulationRender.Client_player = self_player
		self_is_spawned = true
		return
	var new_player = PlayerCharacter.instantiate()
	print("Instantiating new player. ", nickname)
	new_player.username = nickname
	new_player.position = Vector2.ZERO
	players_id[id] = new_player
	get_parent().add_child(new_player)
	#print("added child player")
	new_player.username_label.text = nickname
	
func update_player_nickname(username: String):
	print("Updating player name.")
	SimulationRender.Client_player.username_label.text = username

func update_players_position_graphical(id: int , x: float, y: float):
	if not players_id.has(id):
		print("Player ", id, " does not exist")
		return
	players_id[id].position = players_id[id].position.lerp(Vector2(x, y), Shared.CORRECTION_RATE * 0.05)
