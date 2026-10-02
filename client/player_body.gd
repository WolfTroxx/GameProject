extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var absolute_movement_direction = 0b0000

var x = 0b00000000
var y = 0b00000000

var client_position: Vector2

var encoded_movement = 0b00000000
var last_encoded_movement = 0b00000000

@onready var Parent_node = get_node("../NetworkManager")

func _physics_process(delta: float) -> void:
	x = 0b0
	y = 0b0
	if Input.is_action_pressed("move_left"):
		x -= 0b1
	if Input.is_action_pressed("move_right"):
		x += 0b1
	if Input.is_action_pressed("move_up"):
		y -= 0b1
	if Input.is_action_pressed("move_down"):
		y += 0b1
	encoded_movement = int(x > 0 ) | int(x < 0 ) << 1 | int(y > 0 ) << 2 | int(y < 0 ) << 3
	if last_encoded_movement != encoded_movement:
		#print("Sending encoded movement: ", encoded_movement)
		Parent_node.send_movement_request(encoded_movement)
	last_encoded_movement = encoded_movement
	if ( x && y ):
		x *= 0.7071
		y *= 0.7071
	velocity = Vector2(x*60, y*60)
	move_and_slide()
	var error = position.distance_to(client_position)
	if error > Shared.POSITION_ACCEPTED_ERROR:
		position = position.lerp(client_position, Shared.CORRECTION_RATE * delta)
		print("Corrected position, mismatch: ", error)
		
#func _input(event):
	#if event is InputEventKey:
		#print(event.keycode, " pressed=", event.pressed, " echo=", event.echo)
