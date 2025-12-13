extends "base_sound_manager.gd"
## [Infrastructure Layer]
## UI/ゲームイベント用の非位置依存サウンドマネージャー
##
## [AudioStreamPlayer]を使用して、位置情報を持たないサウンドを再生するマネージャークラスです。
## UIサウンド、BGM、システム効果音など、定位が不要なサウンドの再生に使用します。
##
## [b]使用方法:[/b]
## [codeblock]
## # 直接インスタンス化
## var sound_mgr := SoundManager.new()
## add_child(sound_mgr)
## sound_mgr.play(preload("res://sounds/button_click.wav"))
##
## # Autoloadとして登録（推奨）
## # Project Settings > Autoload で登録後
## SoundManager.play(preload("res://sounds/button_click.wav"))
## [/codeblock]

#region Abstract Methods

## AudioStreamPlayer を作成
func _create_player() -> Node:
	var player := AudioStreamPlayer.new()
	player.bus = bus
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

## サウンドを再生します。
##
## 指定したサウンドを再生キューに追加します。キューが満杯の場合、[param always_play]が[code]true[/code]
## でない限り再生がスキップされます。
##
## [param sound]: 再生するオーディオストリーム
## [param volume_db]: 音量（デシベル単位、デフォルト: 0.0）
## [param pitch_random]: ピッチのランダム範囲（±この値の範囲でランダム化、デフォルト: 0.0）
## [param always_play]: [code]true[/code]の場合、キューが満杯でも強制的に再生します（デフォルト: false）
func play(
		sound: AudioStream,
		volume_db: float = 0.0,
		pitch_random: float = 0.0,
		always_play: bool = false,
) -> void:
	_queue_sound(QueueData.new(sound, volume_db, pitch_random, always_play))

#endregion
