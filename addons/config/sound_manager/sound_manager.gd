extends "base_sound_manager.gd"
## [Infrastructure Layer]
## UI/ゲームイベント用の非位置依存サウンドマネージャー

#region Abstract Methods

## AudioStreamPlayer を作成
func _create_player() -> Node:
	var player := AudioStreamPlayer.new()
	player.bus = &"Sfx"
	return player


## キューからサウンドを再生
func _play_from_queue(player: Node, data: QueueData) -> void:
	var audio_player := player as AudioStreamPlayer
	assert(audio_player != null)

	audio_player.stream = data.stream
	audio_player.volume_db = data.volume_db
	audio_player.pitch_scale = data.get_pitch_random_value()
	audio_player.play()

#endregion

#region Public Methods

## Play sound
func play(
		sound: AudioStream,
		volume_db: float = 0.0,
		pitch_random: float = 0.0,
		always_play: bool = false,
) -> void:
	_queue_sound(QueueData.new(sound, volume_db, pitch_random, always_play))

#endregion
