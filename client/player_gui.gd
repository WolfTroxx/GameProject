extends VBoxContainer


@onready var input_connection: = get_node("HBoxContainer")
@onready var input_username: = get_node("HBoxContainer2")
@onready var input_spawn: = get_node("HBoxContainer3")
@onready var NetworkManager: = get_node("../NetworkManager")

var user_nickname: String
var player_connected: String



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_connection.get_node("Button").button_down.connect(NetworkManager.connect_to_server)
	input_connection.get_node("Button").button_down.connect(_player_connected)
	input_spawn.get_node("Button").button_down.connect(spawn_player_request)
	input_username.get_node("LineEdit").max_length = 16
	input_username.get_node("LineEdit").text_changed.connect(InputUser_edit)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _player_connecting():
	input_connection.get_node("Label").add_theme_color_override("font_color", Color(1.0, 0.439, 0.0, 1.0))
	input_connection.get_node("Label").text = "Connecting" 
	
func _player_connected():
	input_connection.get_node("Button").disabled = true
	input_connection.get_node("Label").add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	input_connection.get_node("Label").text = "Connected" 

func _player_disconnected():
	input_connection.get_node("Label").add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
	input_connection.get_node("Label").text = "Disconnected"

func spawn_player_request():
	if user_nickname.strip_edges().is_empty():
		input_username.get_node("LineEdit").placeholder_text = "Enter username"
		return
	NetworkManager.spawn_player(user_nickname)
	input_spawn.get_node("Button").disabled = true
func InputUser_edit(new_name: String):
	user_nickname = new_name.strip_edges()
	print("New username: ", user_nickname)
