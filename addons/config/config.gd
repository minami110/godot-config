extends Node
## [Infrastructure Layer - Data Model]
## ゲーム設定管理クラス
##
## Local設定とSync設定を管理するシングルトンクラス。
## 設定はConfigFileを使用してファイルに保存される。
##
## このクラスは Config autoload として直接アクセスしてください。
## 例: Config.is_local_config_exist()

const SettingProperty := preload("internal/setting_property.gd")

## 設定ファイル内のセクション名（フラット構造）
const _SETTINGS_SECTION := "Settings"

var _root_dir_path: String
var _user_id: String
var _is_initialized: bool = false

# Config Properties
# キー構造: {filename: {setting_name: ReactiveProperty}}
var _local_properties: Dictionary[String, Dictionary] = { }
var _sync_properties: Dictionary[String, Dictionary] = { }

#region Public Methods

## 初期化メソッド
##
## 設定ファイルの保存先ディレクトリとユーザーIDを設定し、既存の設定ファイルを読み込む。
## Startup autoload から呼び出されます。
##
## @param root_dir 設定ファイルの保存先ルートディレクトリ
## @param user_id ユーザー識別子
func initialize(root_dir: String, user_id: String) -> void:
	if _is_initialized:
		push_warning("[Config] Already initialized")
		return

	print("[Config] Initializing with root_dir: %s, user_id: %s" % [root_dir, user_id])

	_root_dir_path = root_dir
	_user_id = user_id
	_is_initialized = true

	# 既存の設定ファイルを読み込み（存在する場合）
	_load_all_configs()


## Local設定が存在するか確認
##
## @param name 設定キー名
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return 設定が存在する場合はtrue
@warning_ignore("shadowed_variable_base_class")
func has_local_setting(name: String, filename: String = "local") -> bool:
	if not _local_properties.has(filename):
		return false
	return _local_properties[filename].has(name)


## Local設定を取得
##
## @param name 設定キー名
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return 設定値（Variant）または null（設定が存在しない場合）
@warning_ignore("shadowed_variable_base_class")
func get_local_setting(name: String, filename: String = "local") -> Variant:
	if has_local_setting(name, filename):
		return _local_properties[filename][name].get_value()
	return null


## Local設定を作成
##
## @param name 設定キー名
## @param default_value デフォルト値
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return 新規作成した場合はtrue、既存の場合はfalse
@warning_ignore("shadowed_variable_base_class")
func create_local_setting(name: String, default_value: Variant, filename: String = "local") -> bool:
	if has_local_setting(name, filename):
		return false

	# ファイル名のエントリが存在しない場合は作成
	if not _local_properties.has(filename):
		_local_properties[filename] = { }

	_local_properties[filename][name] = SettingProperty.new(default_value)
	return true


## Sync設定が存在するか確認
##
## @param name 設定キー名
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return 設定が存在する場合はtrue
@warning_ignore("shadowed_variable_base_class")
func has_sync_setting(name: String, filename: String = "sync") -> bool:
	if not _sync_properties.has(filename):
		return false
	return _sync_properties[filename].has(name)


## Sync設定を取得
##
## @param name 設定キー名
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return 設定値（Variant）または null（設定が存在しない場合）
@warning_ignore("shadowed_variable_base_class")
func get_sync_setting(name: String, filename: String = "sync") -> Variant:
	if has_sync_setting(name, filename):
		return _sync_properties[filename][name].get_value()
	return null


## Sync設定を作成
##
## @param name 設定キー名
## @param default_value デフォルト値
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return 新規作成した場合はtrue、既存の場合はfalse
@warning_ignore("shadowed_variable_base_class")
func create_sync_setting(name: String, default_value: Variant, filename: String = "sync") -> bool:
	if has_sync_setting(name, filename):
		return false

	# ファイル名のエントリが存在しない場合は作成
	if not _sync_properties.has(filename):
		_sync_properties[filename] = { }

	_sync_properties[filename][name] = SettingProperty.new(default_value)
	return true


## Local設定ファイルの存在確認
##
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return ファイルが存在する場合はtrue
func is_local_config_exist(filename: String = "local") -> bool:
	var file_path: String = _get_local_config_path(filename)
	return FileAccess.file_exists(file_path)


## Sync設定ファイルの存在確認
##
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return ファイルが存在する場合はtrue
func is_sync_config_exist(filename: String = "sync") -> bool:
	var file_path: String = _get_sync_config_path(filename)
	return FileAccess.file_exists(file_path)


func save_local(filename: String = "local") -> bool:
	return _save_local_config(filename)


func save_sync(filename: String = "sync") -> bool:
	return _save_sync_config(filename)


## Local設定の値を設定
##
## @param name 設定キー名
## @param value 設定する値
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return 設定が存在する場合はtrue、存在しない場合はfalse
@warning_ignore("shadowed_variable_base_class")
func set_local_setting(name: String, value: Variant, filename: String = "local") -> bool:
	if not has_local_setting(name, filename):
		return false
	_local_properties[filename][name].set_value(value)
	return true


## Sync設定の値を設定
##
## @param name 設定キー名
## @param value 設定する値
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return 設定が存在する場合はtrue、存在しない場合はfalse
@warning_ignore("shadowed_variable_base_class")
func set_sync_setting(name: String, value: Variant, filename: String = "sync") -> bool:
	if not has_sync_setting(name, filename):
		return false
	_sync_properties[filename][name].set_value(value)
	return true


## Local設定の変更を購読
##
## @param name 設定キー名
## @param callback コールバック関数（引数: Variant）
## @param filename 設定ファイル名（拡張子なし、デフォルト: "local"）
## @return ConfigSubscription（購読オブジェクト）または null（設定が存在しない場合）
@warning_ignore("shadowed_variable_base_class")
func subscribe_local_setting(
		name: String,
		callback: Callable,
		filename: String = "local",
) -> ConfigSubscription:
	if not has_local_setting(name, filename):
		return null
	var prop: RefCounted = _local_properties[filename][name]
	callback.call(prop.get_value()) # 即座に現在値で呼び出し
	return ConfigSubscription.new(prop.value_changed, callback)


## Sync設定の変更を購読
##
## @param name 設定キー名
## @param callback コールバック関数（引数: Variant）
## @param filename 設定ファイル名（拡張子なし、デフォルト: "sync"）
## @return ConfigSubscription（購読オブジェクト）または null（設定が存在しない場合）
@warning_ignore("shadowed_variable_base_class")
func subscribe_sync_setting(
		name: String,
		callback: Callable,
		filename: String = "sync",
) -> ConfigSubscription:
	if not has_sync_setting(name, filename):
		return null
	var prop: RefCounted = _sync_properties[filename][name]
	callback.call(prop.get_value()) # 即座に現在値で呼び出し
	return ConfigSubscription.new(prop.value_changed, callback)


## 設定を保存
##
## すべてのLocal設定とSync設定をファイルに保存する。
##
## @return すべての保存が成功した場合はtrue
func save_all() -> bool:
	var result := true

	# すべてのLocal設定ファイルを保存
	for filename: String in _local_properties:
		if not _save_local_config(filename):
			result = false

	# すべてのSync設定ファイルを保存
	for filename: String in _sync_properties:
		if not _save_sync_config(filename):
			result = false

	return result

#endregion

# ----- Private Methods: Path Helpers -----

## Local設定ファイルのパスを取得
##
## @param filename 設定ファイル名（拡張子なし）
## @return 設定ファイルのフルパス
func _get_local_config_path(filename: String) -> String:
	return _root_dir_path.path_join(filename + ".cfg")


## Sync設定ファイルのパスを取得
##
## @param filename 設定ファイル名（拡張子なし）
## @return 設定ファイルのフルパス
func _get_sync_config_path(filename: String) -> String:
	return _root_dir_path.path_join(_user_id).path_join(filename + ".cfg")


## Local設定ファイルのディレクトリパスを取得
##
## @return ディレクトリパス
func _get_local_config_dir() -> String:
	return _root_dir_path


## Sync設定ファイルのディレクトリパスを取得
##
## @return ディレクトリパス
func _get_sync_config_dir() -> String:
	return _root_dir_path.path_join(_user_id)

# ----- Private Methods: File Operations -----


## ディレクトリ存在確認・作成
##
## @param dir_path 確認・作成するディレクトリパス
## @return 成功した場合はtrue
static func _ensure_directory_exists(dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir_path):
		var dir_error := DirAccess.make_dir_recursive_absolute(dir_path)
		if dir_error != OK:
			push_error("Failed to create directory: %s, error: %s" % [dir_path, error_string(dir_error)])
			return false
	return true


## ConfigFileの読み込み
##
## @param file_path 読み込み元ファイルパス
## @return 読み込みに成功した場合はConfigFileオブジェクト、失敗した場合はnull
static func _load_config_file(file_path: String) -> ConfigFile:
	if not FileAccess.file_exists(file_path):
		print("[Config] Config file not found: %s (using defaults)" % file_path)
		return null

	var config := ConfigFile.new()
	var load_error := config.load(file_path)
	if load_error != OK:
		push_error("Failed to load config file: %s, error: %s" % [file_path, error_string(load_error)])
		return null

	print("[Config] Config loaded successfully from %s" % file_path)
	return config


## ConfigFileの保存
##
## @param config 保存するConfigFileオブジェクト
## @param file_path 保存先ファイルパス
## @return 成功した場合はtrue
static func _save_config_file(config: ConfigFile, file_path: String) -> bool:
	var save_error := config.save(file_path)
	if save_error != OK:
		push_error("Failed to save_all config file: %s, error: %s" % [file_path, error_string(save_error)])
		return false

	print("[Config] Config saved successfully to %s" % file_path)
	return true

# ----- Private Methods: Load/Save Logic -----


## すべての設定ファイルを読み込み
func _load_all_configs() -> void:
	# user:// 直下のすべての .cfg ファイルを探索してLocal設定として読み込み
	var local_dir := DirAccess.open(_root_dir_path)
	if local_dir:
		local_dir.list_dir_begin()
		var file_name := local_dir.get_next()
		while file_name != "":
			if not local_dir.current_is_dir() and file_name.ends_with(".cfg"):
				var filename_without_ext := file_name.trim_suffix(".cfg")
				_load_local_config(filename_without_ext)
			file_name = local_dir.get_next()
		local_dir.list_dir_end()

	# user://{user_id}/ 内のすべての .cfg ファイルを探索してSync設定として読み込み
	var sync_dir_path := _get_sync_config_dir()
	if DirAccess.dir_exists_absolute(sync_dir_path):
		var sync_dir := DirAccess.open(sync_dir_path)
		if sync_dir:
			sync_dir.list_dir_begin()
			var file_name := sync_dir.get_next()
			while file_name != "":
				if not sync_dir.current_is_dir() and file_name.ends_with(".cfg"):
					var filename_without_ext := file_name.trim_suffix(".cfg")
					_load_sync_config(filename_without_ext)
				file_name = sync_dir.get_next()
			sync_dir.list_dir_end()


## Local設定ファイルを読み込み
##
## @param filename 設定ファイル名（拡張子なし）
## @return 成功した場合はtrue
func _load_local_config(filename: String) -> bool:
	var file_path: String = _get_local_config_path(filename)
	var config: ConfigFile = _load_config_file(file_path)
	if config == null:
		return false

	# ファイルから設定値を読み込み、ReactivePropertyを動的生成
	if not _local_properties.has(filename):
		_local_properties[filename] = { }

	if config.has_section(_SETTINGS_SECTION):
		for key: String in config.get_section_keys(_SETTINGS_SECTION):
			var loaded_value: Variant = config.get_value(_SETTINGS_SECTION, key)
			if _local_properties[filename].has(key):
				# 既存のプロパティがあれば値を更新
				_local_properties[filename][key].set_value(loaded_value)
			else:
				# なければ新規作成
				_local_properties[filename][key] = SettingProperty.new(loaded_value)

	return true


## Sync設定ファイルを読み込み
##
## @param filename 設定ファイル名（拡張子なし）
## @return 成功した場合はtrue
func _load_sync_config(filename: String) -> bool:
	var file_path: String = _get_sync_config_path(filename)
	var config: ConfigFile = _load_config_file(file_path)
	if config == null:
		return false

	# ファイルから設定値を読み込み、ReactivePropertyを動的生成
	if not _sync_properties.has(filename):
		_sync_properties[filename] = { }

	if config.has_section(_SETTINGS_SECTION):
		for key: String in config.get_section_keys(_SETTINGS_SECTION):
			var loaded_value: Variant = config.get_value(_SETTINGS_SECTION, key)
			if _sync_properties[filename].has(key):
				# 既存のプロパティがあれば値を更新
				_sync_properties[filename][key].set_value(loaded_value)
			else:
				# なければ新規作成
				_sync_properties[filename][key] = SettingProperty.new(loaded_value)

	return true


## Local設定ファイルを保存
##
## @param filename 設定ファイル名（拡張子なし）
## @return 成功した場合はtrue
func _save_local_config(filename: String) -> bool:
	var dir_path: String = _get_local_config_dir()
	var file_path: String = _get_local_config_path(filename)

	# ConfigFileオブジェクトを作成
	var config := ConfigFile.new()

	# 設定値をConfigFileに保存
	if _local_properties.has(filename):
		for key: String in _local_properties[filename]:
			config.set_value(_SETTINGS_SECTION, key, _local_properties[filename][key].get_value())

	# ディレクトリの存在確認と作成
	if not _ensure_directory_exists(dir_path):
		return false

	# ファイルへの保存
	return _save_config_file(config, file_path)


## Sync設定ファイルを保存
##
## @param filename 設定ファイル名（拡張子なし）
## @return 成功した場合はtrue
func _save_sync_config(filename: String) -> bool:
	var dir_path: String = _get_sync_config_dir()
	var file_path: String = _get_sync_config_path(filename)

	# ConfigFileオブジェクトを作成
	var config := ConfigFile.new()

	# 設定値をConfigFileに保存
	if _sync_properties.has(filename):
		for key: String in _sync_properties[filename]:
			config.set_value(_SETTINGS_SECTION, key, _sync_properties[filename][key].get_value())

	# ディレクトリの存在確認と作成
	if not _ensure_directory_exists(dir_path):
		return false

	# ファイルへの保存
	return _save_config_file(config, file_path)
