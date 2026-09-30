extends Node

const SIMULATOR_DT: = 1.0/10.0
const SNAPSHOT_DT: = 1.0/30.0

var old_simulator_dt: = 0.0
var simulator_acc: = 0.0
var snapshot_acc: = 0.0
var tick: = 0

@onready var Simulator = get_node("../Simulator")
@onready var NetworkManager = get_node("../NetworkManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	simulator_acc += delta
	snapshot_acc += delta

	while simulator_acc >= SIMULATOR_DT:
		Simulator.simulation_tick(simulator_acc - old_simulator_dt, tick)

		tick += 1
		simulator_acc -= SIMULATOR_DT
		old_simulator_dt = simulator_acc

	#while snapshot_acc >= SNAPSHOT_DT:
		#Simulator.snapshot_build()

		#snapshot_acc = 0.0
