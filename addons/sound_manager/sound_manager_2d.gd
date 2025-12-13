extends "base_sound_manager.gd"
## [Infrastructure Layer]
## 位置依存の2Dサウンドマネージャー
##
## [AudioStreamPlayer2D]を使用して、指定した位置でサウンドを再生するマネージャークラスです。
## 足音、攻撃音、環境音など、ゲーム内の特定位置から発生するサウンドの再生に使用します。
##
## [b]使用方法:[/b]
## [codeblock]
## # 直接インスタンス化
## var sound_mgr_2d := SoundManager2D.new()
## add_child(sound_mgr_2d)
## sound_mgr_2d.play(preload("res://sounds/footstep.wav"), player.global_position)
##
## # Autoloadとして登録（推奨）
## # Project Settings > Autoload で登録後
## SoundManager2D.play(preload("res://sounds/footstep.wav"), player.global_position)
## [/codeblock]

#region Abstract Methods

## AudioStreamPlayer2D を作成
func _create_player() -> Node:
	var player := AudioStreamPlayer2D.new()
	player.bus = bus
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

## 2Dサウンドを指定位置で再生します。
##
## 指定した位置で2Dサウンドを再生キューに追加します。キューが満杯の場合、[param always_play]が
## [code]true[/code]でない限り再生がスキップされます。
##
## [param sound]: 再生するオーディオストリーム
## [param global_position]: サウンドを再生するグローバル座標
## [param volume_db]: 音量（デシベル単位、デフォルト: 0.0）
## [param pitch_random]: ピッチのランダム範囲（±この値の範囲でランダム化、デフォルト: 0.0）
## [param always_play]: [code]true[/code]の場合、キューが満杯でも強制的に再生します（デフォルト: false）
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
