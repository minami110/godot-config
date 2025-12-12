@abstract
extends Node
## [Infrastructure Layer]
## サウンドマネージャーの共通基底クラス
##
## サウンドを効率的に再生するための抽象基底クラスです。
## 内部的にキューシステムを使用し、複数のサウンドを同時に再生可能にします。
##
## [b]特徴:[/b]
## - プレイヤープール: 8個のAudioStreamPlayerを事前に作成
## - キューサイズ: 最大32個のサウンドをキューイング可能
## - ポーズ無効: ゲームポーズ中でも動作 ([code]PROCESS_MODE_ALWAYS[/code])
##
## [b]サブクラス実装:[/b]
## サブクラスは [method _create_player] と [method _play_from_queue] を実装する必要があります。

const _QUEUE_SIZE: int = 32
const _PLAYER_COUNT: int = 8

var _available_players: Array[Node] = []
var _queue: Array[QueueData] = []

#region Godot Lifecycle Methods

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			# ポーズ中でも動作する
			process_mode = Node.PROCESS_MODE_ALWAYS

			for i in range(_PLAYER_COUNT):
				var player := _create_player()
				assert(player != null)
				assert(player is AudioStreamPlayer or player is AudioStreamPlayer2D)

				add_child(player)
				_available_players.push_back(player)
				player.finished.connect(_available_players.push_back.bind(player))

			set_process(true)
		NOTIFICATION_PROCESS:
			if _queue.is_empty() or _available_players.is_empty():
				return

			var data: QueueData = _queue.pop_front()
			var player: Node = _available_players.pop_back()
			_play_from_queue(player, data)

#endregion

#region Abstract Methods

## サブクラスで実装: プレイヤーの作成
@abstract
func _create_player() -> Node


## サブクラスで実装: キューからサウンドを再生
@abstract
func _play_from_queue(player: Node, data: QueueData) -> void

#endregion

#region Protected Methods

## キューにサウンドを追加
func _queue_sound(data: QueueData) -> void:
	if not data.is_valid():
		push_warning("[BaseSoundManager] Invalid sound data passed to _queue_sound.")
		return

	if not _available_players.is_empty() and _queue.size() < _QUEUE_SIZE:
		_queue.push_back(data)

	# キューが満杯の場合でも、強制再生フラグが立っていれば先頭を削除して追加
	elif data.force_play:
		_queue.pop_front()
		_queue.push_back(data)

	else:
		push_warning("[BaseSoundManager] Sound queue is full. Sound request ignored.")

#endregion

## サウンドキュー用データクラス
class QueueData extends RefCounted:
	var stream: AudioStream
	var force_play: bool = false
	var volume_db: float
	var pitch_random: float


	func _init(
			p_stream: AudioStream,
			p_volume_db: float = 0.0,
			p_pitch: float = 0.0,
			p_force_play: bool = false,
	) -> void:
		stream = p_stream
		volume_db = p_volume_db
		pitch_random = p_pitch
		force_play = p_force_play


	## キューデータが有効かどうかを検証します。
	##
	## [return]: オーディオストリームが設定されている場合は[code]true[/code]、それ以外は[code]false[/code]
	func is_valid() -> bool:
		return stream != null


	## ランダム化されたピッチ値を取得します。
	##
	## [param pitch_random]で指定された範囲内でランダムなピッチ値を生成します。
	##
	## [return]: -pitch_random から +pitch_random の範囲のランダムなfloat値
	func get_pitch_random_value() -> float:
		return 0.0 + randf_range(-pitch_random, pitch_random)
