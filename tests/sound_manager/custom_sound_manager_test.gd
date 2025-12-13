extends GdUnitTestSuite
## [Test] カスタム SoundManager のテスト

const MockSoundManager := preload("mocks/mock_sound_manager.gd")

var _manager: MockSoundManager
var _mock_stream: AudioStream


func before() -> void:
	# テスト用のオーディオバスを作成
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, "Test")


func before_test() -> void:
	_mock_stream = AudioStreamGenerator.new()


func after_test() -> void:
	if _manager:
		_manager.queue_free()
		_manager = null


func after() -> void:
	AudioServer.remove_bus(AudioServer.get_bus_index("Test"))

#region カスタム設定テスト

func test_custom_player_count_applied() -> void:
	_manager = auto_free(MockSoundManager.new())
	add_child(_manager)
	await get_tree().process_frame

	var player_count := 0
	for child in _manager.get_children():
		if child is AudioStreamPlayer:
			player_count += 1

	assert_int(player_count).is_equal(3)


func test_custom_bus_applied() -> void:
	_manager = auto_free(MockSoundManager.new())
	add_child(_manager)
	await get_tree().process_frame

	# 全プレイヤーのバスが "Test" であることを確認
	for child in _manager.get_children():
		if child is AudioStreamPlayer:
			print(child.bus)
			assert_str(child.bus).is_equal(&"Test")


func test_custom_queue_size_limits_queue() -> void:
	_manager = auto_free(MockSoundManager.new())
	add_child(_manager)
	await get_tree().process_frame

	# 5つのサウンドをキューに追加（queue_size = 4）
	for i in range(5):
		_manager.play(_mock_stream)

	# キューサイズは4に制限されるべき（_queueは直接アクセスできないため、間接的に検証）
	# プレイヤーが3つしかないため、最初のフレームで3つが再生開始
	# キューは 1フレームごとに1つずつ処理されるため、5フレーム待機
	for i in range(5):
		await get_tree().process_frame

	var playing_count := 0
	for child in _manager.get_children():
		if child is AudioStreamPlayer and child.playing:
			playing_count += 1

	# 3つのプレイヤーが再生中であることを確認
	assert_int(playing_count).is_equal(3)


func test_custom_sound_manager_plays_sound() -> void:
	_manager = auto_free(MockSoundManager.new())
	add_child(_manager)
	await get_tree().process_frame

	# 基本的な再生機能のテスト
	_manager.play(_mock_stream, -5.0)
	await get_tree().process_frame

	var found_player := false
	for child in _manager.get_children():
		if child is AudioStreamPlayer and child.playing:
			assert_float(child.volume_db).is_equal(-5.0)
			found_player = true
			break

	assert_bool(found_player).is_true()

#endregion
