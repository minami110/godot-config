extends RefCounted
## [Infrastructure - Object Pooling]
## ノードプーリングを管理するサービス
##
## resource_path をキーとしてプールを管理し、
## 頻繁に生成/破棄されるノードの再利用を可能にする。
##
## == ライフサイクル ==
##
## [b]rent_node() 時:[/b]
## 1. NodePool.rent_node() - プールコンテナから remove_child() → _exit_tree 発火
## 2. NOTIFICATION_EXIT_POOL 送信（シーンツリー外）
## 3. ノードを返却 → 利用者が add_child() → _enter_tree 発火
##
## [b]return_node() 時:[/b]
## 1. 親から remove_child() → _exit_tree 発火
## 2. NOTIFICATION_ENTER_POOL 送信（シーンツリー外）
## 3. NodePool.return_node.call_deferred() → _enter_tree 発火
##
## [b]preload_scene() 時:[/b]
## 1. scene.instantiate()
## 2. NOTIFICATION_ENTER_POOL 送信（シーンツリー外）
## 3. プールコンテナに add_child() → _enter_tree 発火
##
## == Pool 通知を受け取るノードの実装 ==
## - NOTIFICATION_EXIT_POOL で _in_pool = false を設定
## - NOTIFICATION_ENTER_POOL で _in_pool = true を設定
## - _enter_tree で _in_pool フラグをチェックし、true なら処理をスキップ
## - _exit_tree で _in_pool フラグをチェックし、true なら処理をスキップ

const NodePool := preload("./node_pool.gd")
const _SCOPE_KEY: StringName = &"__pool_scope"

## プールのディクショナリ（scope → resource_path → NodePool）
var _pools: Dictionary[StringName, Dictionary] = { }

## シーンキャッシュ（key: resource_path, value: PackedScene）
var _scene_cache: Dictionary[String, PackedScene] = { }

## プールの親ノード（非表示でノードを保持）
var _pool_container: Node = null


func _init(parent: Node) -> void:
	_pool_container = parent


## スコープ名を正規化する
## @param scope 入力スコープ
## @return 正規化されたスコープ
static func _normalize_scope(scope: StringName) -> StringName:
	var path := scope.to_lower().simplify_path()

	# 先頭のスラッシュを除去（simplify_path() は "/" から始まる可能性がある）
	if path.begins_with("/"):
		path = path.substr(1)

	return StringName(path)


## プールからノードを取得する, このノードは SceneTree の外にいる
## @param scene_path シーンのリソースパス
## @param scope スコープ
## @return 利用可能なノード（プールから再利用 or 新規作成）
func rent_node(scene_path: String, scope: StringName = &"") -> Node:
	assert(_pool_container != null, "PoolService: _pool_container が設定されていません")

	var normalized_scope := _normalize_scope(scope)
	var pools: = _get_or_create_pools_in_scope(scope)

	# NodePool が存在しない場合は作成
	if not pools.has(scene_path):
		var scene: PackedScene = _load_scene(scene_path)
		var container := _get_or_create_scope_container(normalized_scope)
		pools[scene_path] = NodePool.new(scene, container)

	# NodePool から利用可能なノードを取得
	var node_pool: NodePool = pools[scene_path]
	# Note: すでにシーンに存在する場合は, ここで remove_child される
	var node: Node = node_pool.rent_node()

	# プールが空の場合は新規作成
	if node == null:
		var scene: PackedScene = _load_scene(scene_path)
		node = scene.instantiate()

	# 通知を送る (ユーザービリティの観点で, 新規作成時にも送信する)
	node.notification(Pool.NOTIFICATION_EXIT_POOL)

	# スコープマップに登録
	node.set_meta(_SCOPE_KEY, _normalize_scope(scope))

	return node


## ノードをプールに返却する
## @param node 返却するノード
func return_node(node: Node) -> void:
	if not is_instance_valid(node):
		push_warning("[PoolService] 無効なノードが返却されました")
		return

	var scene_path: String = node.scene_file_path
	if scene_path.is_empty():
		push_warning("[PoolService] scene_file_path が空のノードは返却できません")
		node.queue_free()
		return

	# スコープを特定
	if node.has_meta(_SCOPE_KEY) == false:
		push_warning("[PoolService] スコープが不明なノードは返却できません")
		node.queue_free()
		return

	var scope: StringName = node.get_meta(_SCOPE_KEY)

	# プールが存在しない場合は破棄
	if not _pools.has(scope) or not _pools[scope].has(scene_path):
		push_warning("[PoolService] 対応するプールが存在しないノードは返却できません")
		node.queue_free()
		return

	# ノードをシーンツリーから取り除く
	if node.is_inside_tree() and node.get_parent() != null:
		node.get_parent().remove_child(node)

	# 通知を送る
	node.notification(Pool.NOTIFICATION_ENTER_POOL)

	var node_pool: NodePool = _pools[scope][scene_path]

	# NOTE: remove のフェーズを待つので defer で呼び出す
	node_pool.return_node.call_deferred(node)


## シーンを事前にプリロードする（ミッション開始時用）
## @param scene_path プリロードするシーンパス
## @param count プリロードする数
## @param scope スコープ
func preload_scene(
		scene_path: String,
		count: int = 5,
		scope: StringName = &"",
) -> void:
	assert(_pool_container != null, "PoolService: _pool_container が設定されていません")

	var normalized_scope := _normalize_scope(scope)
	var pools := _get_or_create_pools_in_scope(scope)

	if not pools.has(scene_path):
		var scene: PackedScene = _load_scene(scene_path)
		var container := _get_or_create_scope_container(normalized_scope)
		pools[scene_path] = NodePool.new(scene, container)

	var pool: NodePool = pools[scene_path]

	# 各ノードを instantiate し、on_enter_pool() を呼び出してから追加
	for i in range(count):
		var scene: PackedScene = _load_scene(scene_path)
		var node: Node = scene.instantiate()

		# 通知を送る
		node.notification(Pool.NOTIFICATION_ENTER_POOL)

		# NodePool に追加（内部で add_child される）
		pool.add_preloaded_node(node)


## 指定スコープとその子スコープのプールをクリアする
## @param scope クリアするスコープ
func clear_scope(scope: StringName) -> void:
	var normalized_scope := _normalize_scope(scope)

	# 空スコープは clear_all_pools 相当
	if normalized_scope == &"":
		clear_all_pools()
		return

	var container := _get_scope_container(normalized_scope)
	if container == null:
		return

	# _pools から該当スコープと子スコープを削除
	var prefix := String(normalized_scope)
	var scopes_to_remove: Array[StringName] = []
	for pool_scope: StringName in _pools.keys():
		var scope_str := String(pool_scope)
		if pool_scope == normalized_scope or scope_str.begins_with(prefix + "/"):
			scopes_to_remove.append(pool_scope)
	for s in scopes_to_remove:
		_pools.erase(s)

	# コンテナを queue_free（子も自動削除）
	container.queue_free()


## 全てのプールをクリアする
func clear_all_pools() -> void:
	# 全ての子ノード（スコープコンテナ）を削除
	for child in _pool_container.get_children():
		child.queue_free()
	_pools.clear()


## 全プールの利用可能ノード合計数を取得（Performance Monitor 用）
## @return 利用可能なノードの合計数
func get_total_available_count() -> int:
	var total: int = 0
	for scope_pools: Dictionary in _pools.values():
		for pool: NodePool in scope_pools.values():
			total += pool.available_count()
	return total


## プールの種類数を取得（Performance Monitor 用）
## @return プールの種類数
func get_pool_type_count() -> int:
	var total: int = 0
	for scope_pools: Dictionary in _pools.values():
		total += scope_pools.size()
	return total


## スコープに対応するコンテナを取得または作成
## @param scope 正規化済みスコープパス (例: "foo/bar")
## @return コンテナノード
func _get_or_create_scope_container(scope: StringName) -> Node:
	# 空スコープは _pool_container 自身を使用
	if scope == &"":
		return _pool_container

	var path := String(scope)
	var segments: PackedStringArray = path.split("/")
	var current_node: Node = _pool_container

	for segment in segments:
		var child := current_node.get_node_or_null(segment)
		if child == null:
			# 中間ノードを作成
			child = Node.new()
			child.name = segment
			current_node.add_child(child)
		current_node = child

	return current_node


## スコープに対応するコンテナを取得する（存在しない場合は null）
## @param scope 正規化済みスコープパス
## @return コンテナノードまたは null
func _get_scope_container(scope: StringName) -> Node:
	if scope == &"":
		return _pool_container

	var path := String(scope)
	var segments: PackedStringArray = path.split("/")
	var current_node: Node = _pool_container

	for segment in segments:
		var child := current_node.get_node_or_null(segment)
		if child == null:
			return null
		current_node = child

	return current_node


func _get_or_create_pools_in_scope(scope: StringName) -> Dictionary[String, NodePool]:
	var normalized_scope := _normalize_scope(scope)

	# スコープが存在しない場合は作成
	if not _pools.has(normalized_scope):
		var new_pools: Dictionary[String, NodePool] = { }
		_pools[normalized_scope] = new_pools

	return _pools[normalized_scope]


## シーンをロードする（キャッシュ使用）
## @param scene_path シーンのリソースパス
## @return ロードされた PackedScene
func _load_scene(scene_path: String) -> PackedScene:
	# キャッシュ済みの場合はそれを返す
	if _scene_cache.has(scene_path):
		return _scene_cache[scene_path]

	var scene := load(scene_path) as PackedScene
	assert(scene != null, "シーンのロードに失敗しました: " + scene_path)
	_scene_cache[scene_path] = scene
	return scene
