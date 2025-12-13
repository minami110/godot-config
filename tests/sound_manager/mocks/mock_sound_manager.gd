extends "res://addons/sound_manager/sound_manager.gd"

func _init() -> void:
	queue_size = 4
	player_count = 3
	bus = &"Test"
