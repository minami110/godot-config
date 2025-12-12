extends "base_sound_manager.gd"
## [Infrastructure Layer]
## 位置依存の2Dサウンドマネージャー

#region Abstract Methods

## AudioStreamPlayer2D を作成
func _create_player() -> Node:
	var player := AudioStreamPlayer2D.new()
	player.bus = &"Sfx"
	return player


## キューからサウンドを再生
func _play_from_queue(player: Node, data: QueueData) -> void:
	var player_2d := player as AudioStreamPlayer2D
	var queue_data := data as QueueData
	assert(player_2d != null)
	assert(queue_data != null)

	player_2d.stream = queue_data.stream
	player_2d.global_position = queue_data.global_position
	player_2d.volume_db = queue_data.volume_db
	player_2d.pitch_scale = queue_data.get_pitch_random_value()
	player_2d.play()

#endregion

#region Public Methods

## Play 2D sound
func play(
		sound: AudioStream,
		global_position: Vector2,
		volume_db: float = 0.0,
		pitch_random: float = 0.0,
		always_play: bool = false,
) -> void:
	_queue_sound(QueueData2D.new(sound, volume_db, pitch_random, global_position, always_play))

#endregion

class QueueData2D extends QueueData:
	var global_position: Vector2


	func _init(
			p_stream: AudioStream,
			p_volume_db: float = 0.0,
			p_pitch: float = 0.0,
			p_global_position: Vector2 = Vector2.ZERO,
			p_force_play: bool = false,
	) -> void:
		super(p_stream, p_volume_db, p_pitch, p_force_play)
		global_position = p_global_position
