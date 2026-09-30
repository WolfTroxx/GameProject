class_name Opcode
extends RefCounted

enum Code { #Operation codes; 1 Byte size maximum
	WORLD_UPDATE =			0b00000001,
	
	NPC_JOIN =				0b10001001,
	PLAYER_JOIN_SELF = 		0b10001000,
	PLAYER_JOIN = 			0b00001000,
	PLAYER_LEAVE =			0b00001001,
	PLAYER_MOVEMENT =		0b00001010,
	PLAYER_MESSAGE =		0b00001011,
	PLAYER_SHOOT =			0b00001100
	
	
	
	
	
}
