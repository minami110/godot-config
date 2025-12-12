extends GdUnitTestSuite
## [Test] SoundManager クラスのテスト

const SoundManagerClass := preload("uid://dm62b6nbuomns")
const SoundManager2DClass := preload("uid://draswj50w43o8")
const BaseSoundManagerClass := preload("uid://ccfa1htbpoxc")

var _sound_manager: SoundManagerClass
var _sound_manager_2d: SoundManager2DClass
var _mock_stream: AudioStream


func before_test() -> void:
	_mock_stream = AudioStreamGenerator.new()


func after_test() -> void:
	if _sound_manager:
		_sound_manager.queue_free()
		_sound_manager = null
	if _sound_manager_2d:
		_sound_manager_2d.queue_free()
		_sound_manager_2d = null

#region SoundManager テスト

func test_sound_manager_creates_8_audio_players_on_ready() -> void:
	_sound_manager = auto_free(SoundManagerClass.new())
	add_child(_sound_manager)

	await get_tree().process_frame

	var player_count := 0
	for child in _sound_manager.get_children():
		if child is AudioStreamPlayer:
			player_count += 1

	assert_int(player_count).is_equal(8)


func test_sound_manager_play_queues_sound() -> void:
	_sound_manager = auto_free(SoundManagerClass.new())
	add_child(_sound_manager)
	await get_tree().process_frame

	# play を呼び出してキューに追加
	_sound_manager.play(_mock_stream)

	# 次のフレームでキューが処理される
	await get_tree().process_frame

	# サウンドが再生されたことを確認（プレイヤーが使用中になる）
	var playing_count := 0
	for child in _sound_manager.get_children():
		if child is AudioStreamPlayer and child.playing:
			playing_count += 1

	assert_int(playing_count).is_greater(0)


func test_sound_manager_respects_volume_and_pitch() -> void:
	_sound_manager = auto_free(SoundManagerClass.new())
	add_child(_sound_manager)

	await get_tree().process_frame

	# play を volume_db と pitch_random 付きで呼び出し
	_sound_manager.play(_mock_stream, -10.0, 0.0)
	await get_tree().process_frame

	# 再生中のプレイヤーを確認
	var found_player := false
	for child in _sound_manager.get_children():
		if child is AudioStreamPlayer and child.playing:
			assert_float(child.volume_db).is_equal(-10.0)
			found_player = true
			break

	assert_bool(found_player).is_true()

#endregion

#region SoundManager2D テスト

func test_sound_manager_2d_creates_8_audio_players_on_ready() -> void:
	_sound_manager_2d = auto_free(SoundManager2DClass.new())

	add_child(_sound_manager_2d)
	await get_tree().process_frame

	var player_count := 0
	for child in _sound_manager_2d.get_children():
		if child is AudioStreamPlayer2D:
			player_count += 1

	assert_int(player_count).is_equal(8)


func test_sound_manager_2d_play_at_position() -> void:
	_sound_manager_2d = auto_free(SoundManager2DClass.new())

	add_child(_sound_manager_2d)
	await get_tree().process_frame

	var test_position := Vector2(100.0, 200.0)
	_sound_manager_2d.play(_mock_stream, test_position)

	await get_tree().process_frame

	# 指定した位置で再生されているか確認
	var found_player := false
	for child in _sound_manager_2d.get_children():
		if child is AudioStreamPlayer2D and child.playing:
			assert_vector(child.global_position).is_equal(test_position)
			found_player = true
			break

	assert_bool(found_player).is_true()

#endregion

#region QueueData テスト

func test_queue_data_is_valid_returns_false_when_stream_is_null() -> void:
	var queue_data := BaseSoundManagerClass.QueueData.new(null)
	assert_bool(queue_data.is_valid()).is_false()


func test_queue_data_is_valid_returns_true_when_stream_is_set() -> void:
	var queue_data := BaseSoundManagerClass.QueueData.new(_mock_stream)
	assert_bool(queue_data.is_valid()).is_true()


func test_queue_data_get_pitch_random_value_returns_zero_when_no_randomization() -> void:
	var queue_data := BaseSoundManagerClass.QueueData.new(_mock_stream, 0.0, 0.0)
	assert_float(queue_data.get_pitch_random_value()).is_equal(0.0)


func test_queue_data_get_pitch_random_value_returns_value_in_range() -> void:
	var queue_data := BaseSoundManagerClass.QueueData.new(_mock_stream, 0.0, 0.5)
	var pitch_value := queue_data.get_pitch_random_value()

	# -0.5 から 0.5 の範囲に収まっているか確認
	assert_float(pitch_value).is_greater_equal(-0.5)
	assert_float(pitch_value).is_less_equal(0.5)

#endregion
