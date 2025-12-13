extends RefCounted
## [Infrastructure Layer - Internal]
## 設定値とシグナルを保持する内部クラス
##
## Config クラス内部でのみ使用される。
## 値の変更を監視し、変更時にシグナルを発行する。

signal value_changed(new_value: Variant)

var _value: Variant


func _init(initial_value: Variant) -> void:
	_value = initial_value


func get_value() -> Variant:
	return _value


func set_value(new_value: Variant) -> void:
	if _value == new_value:
		return
	_value = new_value
	value_changed.emit(new_value)
