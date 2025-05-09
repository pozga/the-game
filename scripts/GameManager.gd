extends Node

# GameManager (Autoload Singleton)
# Used for global game state, settings, scene transitions, etc.

# Example: Game settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0

# Example: Current Score / High Score (if you add persistence)
var current_score: int = 0
var high_score: int = 0

# You might move some power-up definitions or the power-up application logic here
# if it becomes too complex for Game.gd or needs to be accessed globally.

# Called when the game starts
func _ready():
	# Load saved settings/data if any
	# load_game_data()
	print("GameManager is ready.")

# func load_game_data():
	# pass # Implement loading from a file

# func save_game_data():
	# pass # Implement saving to a file

# func go_to_scene(scene_path: String):
	# get_tree().change_scene_to_file(scene_path)

# You could also place the ALL_POWER_UPS array here if it's easier to manage globally
# var ALL_POWER_UPS = [
# 	{ "id": "MAX_HP_SMALL", "name": "Toughness I", "description": "+15 Max HP", "apply_func_name": "apply_max_hp_small" },
# 	# ... etc
# ]

# func get_power_up_options_for_level_up(player_current_powerups) -> Array:
	# Logic to select 3 random, non-acquired power-ups
	# var available_pool = ALL_POWER_UPS.filter(func(pu): return not player_current_powerups.has(pu.id) )
	# available_pool.shuffle()
	# return available_pool.slice(0, min(3, available_pool.size()))

