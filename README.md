# godot-config
[![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![gdunit4-tests](https://github.com/minami110/godot-config/actions/workflows/gdunit4-tests.yml/badge.svg)](https://github.com/minami110/godot-config/actions/workflows/gdunit4-tests.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/minami110/godot-config)

Simple config management addon for Godot Engine 4.5.


## Config Addon

### Installation

1. Download the latest `.zip` from [Releases](https://github.com/minami110/godot-config/releases)
2. Extract and copy `addons/config/` into your project's `addons/` folder
3. Install the dependency: [godot-signal-extensions](https://github.com/minami110/godot-signal-extensions)

### Usage

Register `res://addons/config/config.gd` as an Autoload, or

```gdscript
# Instantiate config.gd where needed.
var config_api: = preload("uid://d3huxhnti6f17").new()
```

## SoundManager Addon

### Installation

1. Download the latest `.zip` from [Releases](https://github.com/minami110/godot-config/releases)
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
