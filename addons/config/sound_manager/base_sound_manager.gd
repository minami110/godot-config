@abstract
extends Node
## [Infrastructure Layer]
## サウンドマネージャーの共通基底クラス

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


	func is_valid() -> bool:
		return stream != null


	func get_pitch_random_value() -> float:
		return 0.0 + randf_range(-pitch_random, pitch_random)
