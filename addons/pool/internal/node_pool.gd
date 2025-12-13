extends RefCounted
## [Infrastructure - Object Pooling]
## 単一シーンタイプのノードプール
##
## 同じシーンから生成されたノードを再利用するためのプール。
## 利用可能なノードのリストを管理し、取得・返却を行う。
##
## == 責任範囲 ==
## - ノードの物理的な管理（add_child / remove_child）
## - 利用可能なノードの配列管理
## - Pool 通知の送信は PoolService が担当

## プールされるシーンの参照
var _scene: PackedScene

## プール内ノードを保持する親ノード
var _container: Node

## 利用可能なノードの配列
var _available: Array[Node] = []


## コンストラクタ
## @param scene プールするシーンの PackedScene
## @param container プール内ノードを保持する親ノード
func _init(scene: PackedScene, container: Node) -> void:
	_scene = scene
	_container = container


## プールからノードを取得する, このノードはシーンツリーの外にいる (PoolContainer から RemoveChild される)
## @return 利用可能なノード。なければ null
func rent_node() -> Node:
	if _available.is_empty():
		return null

	var node: Node = _available.pop_back()

	# プールコンテナから削除
	if node.is_inside_tree() and node.get_parent() == _container:
		_container.remove_child(node)

	return node


## ノードをプールに返却する
## @param node 返却するノード
func return_node(node: Node) -> void:
	assert(_available.find(node) == -1, "NodePool: ノードがすでにプールに存在します")

	# 1. ノードがシーンツリーに存在し, かつプールコンテナの子でない場合は再親化
	if node.is_inside_tree() and node.get_parent() != _container:
		node.reparent(_container)
	# 2. ノードがシーンツリーに存在しない場合はプールコンテナに追加
	elif node.is_inside_tree() == false:
		_container.add_child(node)
	else:
		assert(false, "NodePool: Invalid operation")

	# 配列に追加
	_available.push_back(node)


## 指定数のノードを事前生成する
## @param count 事前生成する数
func preload_nodes(count: int) -> void:
	assert(count > 0, "Argument 'count' must be greater than 0.")

	for i in range(count):
		var node: Node = _scene.instantiate()
		_container.add_child(node)
		_available.push_back(node)


## 事前に準備されたノードをプールに追加する
## @param node 追加するノード（NOTIFICATION_ENTER_POOL 送信済みであること）
func add_preloaded_node(node: Node) -> void:
	assert(_available.find(node) == -1, "NodePool: ノードがすでにプールに存在します")
	_container.add_child(node)
	_available.push_back(node)


## プール内の全ノードを解放する
func clear() -> void:
	for node in _available:
		if is_instance_valid(node):
			node.queue_free()
	_available.clear()


## 利用可能なノード数を取得
## @return 利用可能なノード数
func available_count() -> int:
	return _available.size()
