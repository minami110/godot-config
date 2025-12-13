extends GdUnitTestSuite
## [Test] Config 設定管理クラスのテスト

const ConfigClass := preload("uid://d3huxhnti6f17")

var _config: ConfigClass
var _temp_dir: String
var _test_user_id: String


func before_test() -> void:
	_temp_dir = "user://test_config_temp/"
	_test_user_id = "test_user_123"
	_config = auto_free(ConfigClass.new())
	_config.initialize(_temp_dir, _test_user_id)


func after_test() -> void:
	_cleanup_temp_directory()


func _cleanup_temp_directory() -> void:
	var dir := DirAccess.open(_temp_dir)
	if dir:
		_remove_directory_recursive(_temp_dir)


func _remove_directory_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			var full_path := path.path_join(file_name)
			if dir.current_is_dir():
				_remove_directory_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)

#region Local設定のテスト (create_local_setting)

func test_create_local_setting_returns_true_on_new() -> void:
	var result: bool = _config.create_local_setting("volume", 80)
	assert_bool(result).is_true()


func test_create_local_setting_returns_false_on_duplicate() -> void:
	_config.create_local_setting("volume", 80)
	var result: bool = _config.create_local_setting("volume", 100)
	assert_bool(result).is_false()


func test_create_local_setting_stores_default_value() -> void:
	_config.create_local_setting("volume", 80)
	var value: Variant = _config.get_local_setting("volume")
	assert_int(value).is_equal(80)

#endregion

#region Local設定のテスト (has_local_setting)

func test_has_local_setting_returns_false_when_empty() -> void:
	var result: bool = _config.has_local_setting("volume")
	assert_bool(result).is_false()


func test_has_local_setting_returns_true_after_create() -> void:
	_config.create_local_setting("volume", 80)
	var result: bool = _config.has_local_setting("volume")
	assert_bool(result).is_true()

#endregion

#region Local設定のテスト (get_local_setting)

func test_get_local_setting_returns_null_when_not_exist() -> void:
	var result: Variant = _config.get_local_setting("volume")
	assert_object(result).is_null()


func test_get_local_setting_returns_value() -> void:
	_config.create_local_setting("volume", 80)
	var result: Variant = _config.get_local_setting("volume")
	assert_int(result).is_equal(80)


func test_get_local_setting_returns_default_when_not_exist() -> void:
	var result: Variant = _config.get_local_setting("volume", 50)
	assert_int(result).is_equal(50)


func test_get_local_setting_returns_value_not_default_when_exist() -> void:
	_config.create_local_setting("volume", 80)
	var result: Variant = _config.get_local_setting("volume", 50)
	assert_int(result).is_equal(80) # デフォルト値ではなく実際の値

#endregion

#region Sync設定のテスト (create_sync_setting)

func test_create_sync_setting_returns_true_on_new() -> void:
	var result: bool = _config.create_sync_setting("score", 1000)
	assert_bool(result).is_true()


func test_create_sync_setting_returns_false_on_duplicate() -> void:
	_config.create_sync_setting("score", 1000)
	var result: bool = _config.create_sync_setting("score", 2000)
	assert_bool(result).is_false()


func test_create_sync_setting_stores_default_value() -> void:
	_config.create_sync_setting("score", 1000)
	var value: Variant = _config.get_sync_setting("score")
	assert_int(value).is_equal(1000)

#endregion

#region Sync設定のテスト (has_sync_setting)

func test_has_sync_setting_returns_false_when_empty() -> void:
	var result: bool = _config.has_sync_setting("score")
	assert_bool(result).is_false()


func test_has_sync_setting_returns_true_after_create() -> void:
	_config.create_sync_setting("score", 1000)
	var result: bool = _config.has_sync_setting("score")
	assert_bool(result).is_true()

#endregion

#region Sync設定のテスト (get_sync_setting)

func test_get_sync_setting_returns_null_when_not_exist() -> void:
	var result: Variant = _config.get_sync_setting("score")
	assert_object(result).is_null()


func test_get_sync_setting_returns_value() -> void:
	_config.create_sync_setting("score", 1000)
	var result: Variant = _config.get_sync_setting("score")
	assert_int(result).is_equal(1000)


func test_get_sync_setting_returns_default_when_not_exist() -> void:
	var result: Variant = _config.get_sync_setting("score", 500)
	assert_int(result).is_equal(500)


func test_get_sync_setting_returns_value_not_default_when_exist() -> void:
	_config.create_sync_setting("score", 1000)
	var result: Variant = _config.get_sync_setting("score", 500)
	assert_int(result).is_equal(1000) # デフォルト値ではなく実際の値

#endregion

#region ファイル存在確認のテスト (is_local_config_exist)

func test_is_local_config_exist_returns_false_before_save() -> void:
	_config.create_local_setting("volume", 80)
	var result: bool = _config.is_local_config_exist()
	assert_bool(result).is_false()


func test_is_local_config_exist_returns_true_after_save() -> void:
	_config.create_local_setting("volume", 80)
	_config.save_local()
	var result: bool = _config.is_local_config_exist()
	assert_bool(result).is_true()

#endregion

#region ファイル存在確認のテスト (is_sync_config_exist)

func test_is_sync_config_exist_returns_false_before_save() -> void:
	_config.create_sync_setting("score", 1000)
	var result: bool = _config.is_sync_config_exist()
	assert_bool(result).is_false()


func test_is_sync_config_exist_returns_true_after_save() -> void:
	_config.create_sync_setting("score", 1000)
	_config.save_sync()
	var result: bool = _config.is_sync_config_exist()
	assert_bool(result).is_true()

#endregion

#region 保存のテスト (save_local)

func test_save_local_returns_true_on_success() -> void:
	_config.create_local_setting("volume", 80)
	var result: bool = _config.save_local()
	assert_bool(result).is_true()


func test_save_local_creates_config_file() -> void:
	_config.create_local_setting("volume", 80)
	_config.save_local()
	var file_exists: bool = _config.is_local_config_exist()
	assert_bool(file_exists).is_true()

#endregion

#region 保存のテスト (save_sync)

func test_save_sync_returns_true_on_success() -> void:
	_config.create_sync_setting("score", 1000)
	var result: bool = _config.save_sync()
	assert_bool(result).is_true()


func test_save_sync_creates_config_file() -> void:
	_config.create_sync_setting("score", 1000)
	_config.save_sync()
	var file_exists: bool = _config.is_sync_config_exist()
	assert_bool(file_exists).is_true()

#endregion

#region 保存のテスト (save_all)

func test_save_all_returns_true_on_success() -> void:
	_config.create_local_setting("volume", 80)
	_config.create_sync_setting("score", 1000)
	var result: bool = _config.save_all()
	assert_bool(result).is_true()


func test_save_all_saves_both_local_and_sync() -> void:
	_config.create_local_setting("volume", 80)
	_config.create_sync_setting("score", 1000)
	_config.save_all()
	assert_bool(_config.is_local_config_exist()).is_true()
	assert_bool(_config.is_sync_config_exist()).is_true()

#endregion

#region 永続化と読み込みのテスト

func test_saved_local_config_is_loaded_on_initialize() -> void:
	# 設定を作成して保存
	_config.create_local_setting("volume", 80)
	_config.save_local()

	# 新しいインスタンスで初期化
	var new_config: ConfigClass = auto_free(ConfigClass.new())
	new_config.initialize(_temp_dir, _test_user_id)

	# 設定が読み込まれているか確認
	assert_bool(new_config.has_local_setting("volume")).is_true()
	var value: Variant = new_config.get_local_setting("volume")
	assert_int(value).is_equal(80)


func test_saved_sync_config_is_loaded_on_initialize() -> void:
	# 設定を作成して保存
	_config.create_sync_setting("score", 1000)
	_config.save_sync()

	# 新しいインスタンスで初期化
	var new_config: ConfigClass = auto_free(ConfigClass.new())
	new_config.initialize(_temp_dir, _test_user_id)

	# 設定が読み込まれているか確認
	assert_bool(new_config.has_sync_setting("score")).is_true()
	var value: Variant = new_config.get_sync_setting("score")
	assert_int(value).is_equal(1000)

#endregion

#region カスタムファイル名のテスト

func test_create_local_setting_with_custom_filename() -> void:
	var result: bool = _config.create_local_setting("language", "en", "preferences")
	assert_bool(result).is_true()
	assert_bool(_config.has_local_setting("language", "preferences")).is_true()

	var value: Variant = _config.get_local_setting("language", "none", "preferences")
	assert_str(value).is_equal("en")


func test_create_sync_setting_with_custom_filename() -> void:
	var result: bool = _config.create_sync_setting("level", 5, "progress")
	assert_bool(result).is_true()
	assert_bool(_config.has_sync_setting("level", "progress")).is_true()

	var value: Variant = _config.get_sync_setting("level", -1, "progress")
	assert_int(value).is_equal(5)

#endregion
