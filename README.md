# godot-essentials
[![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![gdunit4-tests](https://github.com/minami110/godot-essentials/actions/workflows/gdunit4-tests.yml/badge.svg)](https://github.com/minami110/godot-essentials/actions/workflows/gdunit4-tests.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/minami110/godot-essentials)



## Config Addon
Simple config management addon for Godot Engine 4.5.

### Installation

1. Download the latest `.zip` from [Releases](https://github.com/minami110/godot-essentials/releases)
2. Extract and copy `addons/config/` into your project's `addons/` folder

### Usage

Register `res://addons/config/config.gd` as an Autoload, or

```gdscript
# Instantiate config.gd where needed.
var config_api: = preload("uid://d3huxhnti6f17").new()
```

## Pool Addon
Object pooling system for frequently instantiated nodes (enemies, bullets, effects, etc.).

### Installation

1. Download the latest `.zip` from [Releases](https://github.com/minami110/godot-essentials/releases)
2. Extract and copy `addons/pool/` into your project's `addons/` folder

### Usage

Register `res://addons/pool/pool.gd` as an Autoload named `Pool`.

```gdscript
# Rent a node from the pool (node is outside SceneTree, use add_child).
var bullet: Node = Pool.rent_node("res://scenes/bullet.tscn")
add_child(bullet)

# Return the node to the pool when done.
Pool.return_node(bullet)

# Preload nodes for better performance.
Pool.preload_scene("res://scenes/bullet.tscn", 20)

# Use scopes to organize pools (e.g., clear all enemies when stage ends).
var enemy: Node = Pool.rent_node("res://scenes/enemy.tscn", &"stage1")
Pool.clear_scope(&"stage1")
```

**Custom Notifications:**
- `Pool.NOTIFICATION_EXIT_POOL` - Sent when node exits the pool (before `_enter_tree`)
- `Pool.NOTIFICATION_ENTER_POOL` - Sent when node enters the pool (before `_enter_tree`)

## SoundManager Addon

### Installation

1. Download the latest `.zip` from [Releases](https://github.com/minami110/godot-essentials/releases)
2. Extract and copy `addons/sound_manager/` into your project's `addons/` folde

### Usage
#### SoundManager (1D)
Register `res://addons/sound_manager/sound_manager.gd` as an Autoload, or

```gdscript
# Instantiate sound_manager.gd where needed.
var sound_manager := preload("uid://dm62b6nbuomns").new()
add_child(sound_manager)
```

#### SoundManager2D

Register `res://addons/sound_manager/sound_manager_2d.gd` as an Autoload, or

```gdscript
# Instantiate sound_manager_2d.gd where needed.
var sound_manager_2d := preload("uid://draswj50w43o8").new()
add_child(sound_manager_2d)
```
