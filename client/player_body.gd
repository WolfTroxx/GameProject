extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var absolute_movement_direction = 0b0000

var x: float
var y: float

var client_position: Vector2
var username: String

var encoded_movement = 0b00000000
var last_encoded_movement = 0b00000000

@onready var Parent_node = get_node("../NetworkManager")
@onready var username_label = get_node("Label")

func _physics_process(delta: float) -> void:
	pass
	#var error = position.distance_to(client_position)
	#if error > Shared.POSITION_ACCEPTED_ERROR:
	#position = position.lerp(client_position, Shared.CORRECTION_RATE * delta)
	
