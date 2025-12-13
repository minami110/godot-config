extends Node
## [Autoload - Object Pooling]
## オブジェクトプーリングのグローバルアクセスポイント
##
## Pool.rent_node(scene_path) / Pool.return_node(node) でアクセス可能。
## 頻繁に生成/破棄されるノード（敵、エフェクト、弾丸など）の
## パフォーマンス最適化のために使用する。

const PoolService := preload("./internal/pool_service.gd")

## SceneTree の外で呼ばれる, Pool から exit_tree した直後に呼ばれる
const NOTIFICATION_EXIT_POOL: int = 200001

## SceneTree の外で呼ばれる, Pool に enter_tree する直前に呼ばれる
const NOTIFICATION_ENTER_POOL: int = 200002

## プーリングロジックの実装クラス
var _service: PoolService


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			_service = PoolService.new(self, NOTIFICATION_EXIT_POOL, NOTIFICATION_ENTER_POOL)
			_register_performance_monitors()


## プールからノードを取得する, このノードは SceneTree の外にいるため add_child() が必要
## @param scene_path シーンのリソースパス
## @param scope スコープ（空文字列の場合は "global"）
## @return 利用可能なノード（プールから再利用 or 新規作成）
func rent_node(scene_path: String, scope: StringName = &"") -> Node:
	return _service.rent_node(scene_path, scope)


## ノードをプールに返却する, この処理で reparent() が行われる
## @param node 返却するノード
func return_node(node: Node) -> void:
	_service.return_node(node)


## シーンを事前にプリロードしてプールに追加(返却)する
## @param scene_path プリロードするシーンパス
## @param count プリロードする数
## @param scope スコープ
func preload_scene(scene_path: String, count: int = 5, scope: StringName = &"") -> void:
	_service.preload_scene(scene_path, count, scope)


## 指定スコープのプールをクリアする
## @param scope クリアするスコープ
func clear_scope(scope: StringName) -> void:
	_service.clear_scope(scope)


## 全てのプールをクリアする
func clear_all() -> void:
	_service.clear_all_pools()


## カスタムパフォーマンスモニターを登録する
func _register_performance_monitors() -> void:
	# カテゴリ "pool" でモニター登録
	Performance.add_custom_monitor(
		&"pool/available",
		_service.get_total_available_count,
	)
	Performance.add_custom_monitor(
		&"pool/types",
		_service.get_pool_type_count,
	)
