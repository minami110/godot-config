extends GdUnitTestSuite
## [Test] ConfigSubscription のテスト

# テスト用シグナル発行クラス
class TestEmitter extends RefCounted:
	signal value_changed(value: Variant)


func test_subscribe_connects_to_signal() -> void:
	# シグナルに接続されることを確認
	var emitter := TestEmitter.new()
	var received_values: Array = []
	var callback := func(v: Variant) -> void: received_values.append(v)

	var _sub := ConfigSubscription.new(emitter.value_changed, callback)
	emitter.value_changed.emit(42)

	assert_array(received_values).contains([42])


func test_unsubscribe_disconnects_from_signal() -> void:
	# unsubscribe後はコールバックが呼ばれない
	var emitter := TestEmitter.new()
	var received_values: Array = []
	var callback := func(v: Variant) -> void: received_values.append(v)

	var sub := ConfigSubscription.new(emitter.value_changed, callback)
	sub.unsubscribe()
	emitter.value_changed.emit(42)

	assert_array(received_values).is_empty()


func test_double_unsubscribe_does_not_error() -> void:
	# 二重unsubscribeでエラーにならない
	var emitter := TestEmitter.new()
	var callback := func(_v: Variant) -> void: pass

	var sub := ConfigSubscription.new(emitter.value_changed, callback)
	sub.unsubscribe()
	sub.unsubscribe() # 二回目もエラーにならない

	assert_bool(true).is_true() # エラーが発生しなければOK
