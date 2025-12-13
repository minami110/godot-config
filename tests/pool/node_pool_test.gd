extends GdUnitTestSuite
## [Test] NodePool のテスト

const NodePool := preload("uid://vsjjfkrrm77v")
const MOCK_SCENE: PackedScene = preload("./mocks/mock_poolable_node.tscn")

var _pool_container: Node
var _pool: NodePool


func before_test() -> void:
	_pool_container = auto_free(Node.new())
	add_child(_pool_container)
	_pool = auto_free(NodePool.new(MOCK_SCENE, _pool_container))


func after_test() -> void:
	# プール内のノードをクリア
	_pool.clear()

#region rent_node() のテスト

func test_get_node_returns_null_when_empty() -> void:
	# 空のプールから取得すると null を返す
	var node: Node = _pool.rent_node()
	assert_object(node).is_null()

#endregion

#region return_node() と rent_node() のテスト

func test_return_node_and_get_node() -> void:
	# ノードを作成してプールに返却
	var node: Node = auto_free(MOCK_SCENE.instantiate())
	_pool.return_node(node)

	# プールから取得すると同じノードが返る
	var retrieved_node: Node = _pool.rent_node()
	assert_object(retrieved_node).is_same(node)

	# プールから取得後、再度取得すると null を返す
	var null_node: Node = _pool.rent_node()
	assert_object(null_node).is_null()

#endregion

#region preload_nodes() のテスト

func test_preload_nodes() -> void:
	# 5個のノードを事前プリロード
	_pool.preload_nodes(5)

	# available_count が 5 になる
	assert_int(_pool.available_count()).is_equal(5)

	# 5回取得できる
	for i in range(5):
		var node: Node = auto_free(_pool.rent_node())
		assert_object(node).is_not_null()

	# 6回目は null を返す
	var null_node: Node = _pool.rent_node()
	assert_object(null_node).is_null()

#endregion

#region available_count() のテスト

func test_available_count() -> void:
	# 初期状態は 0
	assert_int(_pool.available_count()).is_equal(0)

	# 3個のノードを返却
	for i in range(3):
		var node: Node = auto_free(MOCK_SCENE.instantiate())
		_pool.return_node(node)

	# available_count が 3 になる
	assert_int(_pool.available_count()).is_equal(3)

	# 1個取得
	auto_free(_pool.rent_node())

	# available_count が 2 になる
	assert_int(_pool.available_count()).is_equal(2)

#endregion

#region clear() のテスト

func test_clear() -> void:
	# 3個のノードを事前プリロード
	_pool.preload_nodes(3)
	assert_int(_pool.available_count()).is_equal(3)

	# クリア
	_pool.clear()

	# available_count が 0 になる
	assert_int(_pool.available_count()).is_equal(0)

	# プールから取得すると null を返す
	var node: Node = _pool.rent_node()
	assert_object(node).is_null()

#endregion
