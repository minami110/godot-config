extends Node2D
## [Mock] Pool 通知用のモック Node
##
## テスト用に Pool 通知とライフサイクルの呼び出し順序を記録する。

const Pool := preload("uid://mxd1go2i1jv3")

## プール内にいるかどうかを示すフラグ
var in_pool: bool = false

## 呼び出し順序を記録する配列
var call_order: Array[String] = []


func _notification(what: int) -> void:
	match what:
		Pool.NOTIFICATION_EXIT_POOL:
			in_pool = false
			call_order.append("NOTIFICATION_EXIT_POOL")
		Pool.NOTIFICATION_ENTER_POOL:
			in_pool = true
			call_order.append("NOTIFICATION_ENTER_POOL")
		NOTIFICATION_ENTER_TREE:
			call_order.append("_enter_tree")
		NOTIFICATION_EXIT_TREE:
			call_order.append("_exit_tree")


## 呼び出し順序をリセット（テスト用）
func reset_call_order() -> void:
	call_order.clear()
