extends GdUnitTestSuite
## [Test] PoolService のテスト

const PoolService := preload("uid://b2e6gvs6mm8by")
const MOCK_SCENE_PATH: String = "res://tests/pool/mocks/mock_poolable_node.tscn"

var _pool_container: Node
var _service: PoolService


func before_test() -> void:
	_pool_container = auto_free(Node.new())
	add_child(_pool_container)
	_service = auto_free(PoolService.new(_pool_container))


func after_test() -> void:
	# プール内のノードをクリア
	_service.clear_all_pools()

#region acquire() のテスト

func test_acquire_creates_new_node_when_pool_empty() -> void:
	# 空のプールから取得すると新しいノードを作成
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
	assert_object(node).is_not_null()
	assert_str(node.scene_file_path).is_equal(MOCK_SCENE_PATH)

#endregion

#region release() と acquire() のテスト

func test_release_and_acquire_reuses_node() -> void:
	# ノードを取得
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
	var original_node := node

	# プールに返却
	_service.return_node(node)
	await await_millis(100) # call_deferred を待つ

	# 再度取得すると同じノードが返る
	var reused_node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
	assert_object(reused_node).is_same(original_node)

#endregion

#region Pool 通知のテスト

func test_notification_exit_pool_on_rent() -> void:
	# rent 時に NOTIFICATION_EXIT_POOL が送信される
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
	assert_bool(node.in_pool).is_false()


func test_notification_enter_pool_on_return() -> void:
	# return 時に NOTIFICATION_ENTER_POOL が送信される
	var node: Node = _service.rent_node(MOCK_SCENE_PATH)
	_service.return_node(node)
	assert_bool(node.in_pool).is_true()

#endregion

#region preload_scene() のテスト

func test_preload_scene() -> void:
	# 5個のノードを事前プリロード
	_service.preload_scene(MOCK_SCENE_PATH, 5)

	# available_count が 5 になる
	assert_int(_service.get_total_available_count()).is_equal(5)

	# 5回取得できる
	for i in range(5):
		var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
		assert_object(node).is_not_null()

	# 6回目も新規作成される
	var new_node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))
	assert_object(new_node).is_not_null()

#endregion

#region get_total_available_count() のテスト

func test_get_total_available_count() -> void:
	# 初期状態は 0
	assert_int(_service.get_total_available_count()).is_equal(0)

	# 3個のノードを取得して返却
	var nodes: Array[Node] = []
	for i in range(3):
		var node: Node = _service.rent_node(MOCK_SCENE_PATH)
		nodes.append(node)

	for node in nodes:
		_service.return_node(node)

	await await_millis(100)

	# available_count が 3 になる
	assert_int(_service.get_total_available_count()).is_equal(3)

#endregion

#region get_pool_type_count() のテスト

func test_get_pool_type_count() -> void:
	# 初期状態は 0
	assert_int(_service.get_pool_type_count()).is_equal(0)

	# 1つのシーンからノードを取得
	auto_free(_service.rent_node(MOCK_SCENE_PATH))

	# pool_type_count が 1 になる
	assert_int(_service.get_pool_type_count()).is_equal(1)

#endregion

#region clear_all_pools() のテスト

func test_clear_all_pools() -> void:
	# 3個のノードを事前プリロード
	_service.preload_scene(MOCK_SCENE_PATH, 3)
	assert_int(_service.get_total_available_count()).is_equal(3)

	# 全プールクリア
	_service.clear_all_pools()

	# available_count が 0 になる
	assert_int(_service.get_total_available_count()).is_equal(0)

	# pool_type_count が 0 になる
	assert_int(_service.get_pool_type_count()).is_equal(0)

#endregion

#region スコープ機能のテスト

func test_acquire_with_scope() -> void:
	# 異なるスコープでノードを取得
	var node_global: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"global"))
	var node_ingame: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"ingame"))

	# 両方とも有効なノード
	assert_object(node_global).is_not_null()
	assert_object(node_ingame).is_not_null()


func test_clear_scope() -> void:
	# 2つのスコープでプリロード
	_service.preload_scene(MOCK_SCENE_PATH, 3, &"global")
	_service.preload_scene(MOCK_SCENE_PATH, 2, &"ingame")

	# 合計 5 個
	assert_int(_service.get_total_available_count()).is_equal(5)

	# ingame スコープのみクリア
	_service.clear_scope(&"ingame")

	await await_millis(100) # queue_free を待つ

	# global の 3 個のみ残る
	assert_int(_service.get_total_available_count()).is_equal(3)


func test_release_returns_to_correct_scope() -> void:
	# ingame スコープでノードを取得
	var node: Node = _service.rent_node(MOCK_SCENE_PATH, &"ingame")

	# プールに返却
	_service.return_node(node)
	await await_millis(100)

	# ingame スコープで取得すると同じノードが返る
	var reused: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"ingame"))
	assert_object(reused).is_same(node)

#endregion

#region Pool ライフサイクル順序テスト

## preload 後に NOTIFICATION_ENTER_POOL が送信されることを確認
func test_preload_sends_notification_enter_pool() -> void:
	_service.preload_scene(MOCK_SCENE_PATH, 3)

	# preload されたノードを取得
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH))

	# rent 時に NOTIFICATION_EXIT_POOL が送信され、in_pool = false になる
	assert_bool(node.in_pool).is_false()


## rent 時の呼び出し順序: _exit_tree → NOTIFICATION_EXIT_POOL
func test_rent_lifecycle_order() -> void:
	# preload でノードを用意
	_service.preload_scene(MOCK_SCENE_PATH, 1)

	var node: Node = _service.rent_node(MOCK_SCENE_PATH)

	# 呼び出し順序をリセットして、rent 以降の動作を確認
	node.reset_call_order()

	# この時点で NOTIFICATION_EXIT_POOL が送信されているが、まだシーンツリー外
	assert_bool(node.in_pool).is_false()
	assert_bool(node.is_inside_tree()).is_false()

	# add_child すると _enter_tree が発火
	add_child(node)
	auto_free(node)
	assert_bool(node.is_inside_tree()).is_true()

	# 最後の呼び出しが _enter_tree であることを確認
	assert_int(node.call_order.size()).is_equal(1)
	assert_str(node.call_order[0]).is_equal("_enter_tree")


## return 時の呼び出し順序: _exit_tree → NOTIFICATION_ENTER_POOL
func test_return_lifecycle_order() -> void:
	var node: Node = _service.rent_node(MOCK_SCENE_PATH)
	add_child(node)

	# 呼び出し順序をリセット
	node.reset_call_order()

	# return_node を呼ぶと remove_child → NOTIFICATION_ENTER_POOL の順
	_service.return_node(node)

	# NOTIFICATION_ENTER_POOL が送信されている
	assert_bool(node.in_pool).is_true()
	# シーンツリーから外れている（remove_child 済み）
	assert_bool(node.is_inside_tree()).is_false()

	# 呼び出し順序を確認: _exit_tree → NOTIFICATION_ENTER_POOL
	assert_int(node.call_order.size()).is_equal(2)
	assert_str(node.call_order[0]).is_equal("_exit_tree")
	assert_str(node.call_order[1]).is_equal("NOTIFICATION_ENTER_POOL")

	await await_millis(100) # call_deferred を待つ

#endregion

#region 階層スコープのテスト

func test_hierarchical_scope_creation() -> void:
	# 階層的なスコープでノードを取得
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"foo/bar"))
	assert_object(node).is_not_null()

	# コンテナ階層が作成されていることを確認
	var foo_container := _pool_container.get_node_or_null("foo")
	assert_object(foo_container).is_not_null()

	var bar_container := foo_container.get_node_or_null("bar")
	assert_object(bar_container).is_not_null()


func test_clear_parent_scope_clears_children() -> void:
	# 親と子のスコープでプリロード
	_service.preload_scene(MOCK_SCENE_PATH, 2, &"foo")
	_service.preload_scene(MOCK_SCENE_PATH, 3, &"foo/bar")
	_service.preload_scene(MOCK_SCENE_PATH, 1, &"foo/bar/baz")

	# 合計 6 個
	assert_int(_service.get_total_available_count()).is_equal(6)

	# 親スコープをクリア
	_service.clear_scope(&"foo")

	await await_millis(100) # queue_free を待つ

	# 全てクリアされる
	assert_int(_service.get_total_available_count()).is_equal(0)

	# コンテナノードも削除されている
	var foo_container := _pool_container.get_node_or_null("foo")
	assert_object(foo_container).is_null()


func test_empty_scope_behavior() -> void:
	# 空スコープでノードを取得
	var node: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &""))
	assert_object(node).is_not_null()

	# 空スコープのノードは _pool_container 直下に配置される
	_service.return_node(node)
	await await_millis(100)

	# ノードが _pool_container の直接の子として存在することを確認
	assert_int(_service.get_total_available_count()).is_equal(1)


func test_scope_normalization() -> void:
	# 異なる形式で同じスコープを指定
	var node1: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"FOO/BAR"))
	_service.return_node(node1)
	await await_millis(100)

	# 正規化された形式で取得しても同じノード
	var node2: Node = auto_free(_service.rent_node(MOCK_SCENE_PATH, &"foo/bar"))
	assert_object(node2).is_same(node1)


func test_clear_scope_preserves_sibling_scopes() -> void:
	# 兄弟スコープでプリロード
	_service.preload_scene(MOCK_SCENE_PATH, 2, &"foo/bar")
	_service.preload_scene(MOCK_SCENE_PATH, 3, &"foo/baz")

	# 合計 5 個
	assert_int(_service.get_total_available_count()).is_equal(5)

	# bar のみクリア
	_service.clear_scope(&"foo/bar")

	await await_millis(100)

	# baz の 3 個のみ残る
	assert_int(_service.get_total_available_count()).is_equal(3)

#endregion
