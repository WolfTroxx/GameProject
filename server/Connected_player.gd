class_name ConnectedPlayer
extends RefCounted
##Player object
##
##Contains WebSocket connection, username and authentication bool

##Login credential name
var account_name: String

##Login credential password
var account_password: String

##Variable which contains corresponding WebSocketPeer, can be used to send packages
var websocket: WebSocketPeer

##WebSocket id of player
var WS_id: int

##Username of the corresponding player
var username: String = ""

##Authentication boolean
var authenticated: bool = false

##Current player IP address
var ip_address: String

##If player is currently loaded into world
var world_loaded: bool = false

##Player data object
var player_data: PlayerData

func _init(
	player_websocket: WebSocketPeer
):
	websocket = player_websocket
