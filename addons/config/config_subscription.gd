class_name ConfigSubscription
extends RefCounted
## [Infrastructure Layer - Data Model]
## 設定変更購読管理クラス
##
## Config.subscribe_xxx_setting() が返す購読オブジェクト。
## unsubscribe() メソッドでシグナル接続を解除できる。

var _signal: Signal = Signal()
var _callback: Callable = Callable()


func _init(sig: Signal, callback: Callable) -> void:
	# Note: Signal.is_zero() == Signal.is_null()
	if not sig:
		push_error("Signal is null")
		return

	# Already freed signal's owner
	if not is_instance_id_valid(sig.get_object_id()):
		push_error("Signal's owner is already freed")
		return

	# Check connection
	if sig.is_connected(callback):
		push_error("Signal is already connected")
		return

	var success := sig.connect(callback)
	if success != OK:
		push_error("Failed to connect signal")
		return

	_signal = sig
	_callback = callback


## 購読を解除
##
## シグナル接続を切断し、以降コールバックは呼ばれなくなる。
## 複数回呼び出しても安全。
func unsubscribe() -> void:
	if not _signal:
		return

	# Check freed signal's owner
	if not is_instance_id_valid(_signal.get_object_id()):
		_signal = Signal()
		_callback = Callable()
		return

	if _signal.is_connected(_callback):
		_signal.disconnect(_callback)

	_signal = Signal()
	_callback = Callable()
