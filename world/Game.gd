extends Node2D

@onready var player = $Player # Assuming Player is a child of Game node
@onready var tile_map = $TerrainTileMap # Assuming a TileMap child
@onready var game_ui = $GameUI # Assuming GameUI is a child canvas layer

# Wave Management
var current_wave: int = 0
var waves_before_king: int = 3
var king_rat_spawned_this_cycle: bool = false
const RatScene = preload("res://enemies/Rat.tscn")
const KingRatScene = preload("res://enemies/KingRat.tscn")

# Enemy spawn points (optional, or spawn randomly)
@onready var enemy_spawn_points_parent = $EnemySpawnPoints # An optional Node2D holding Position2D nodes
var enemy_spawn_points = []

var game_over_flag: bool = false
var game_paused_for_level_up: bool = false

func _ready():
	# Add player to a group for easy access by enemies
	player.add_to_group("player")

	if enemy_spawn_points_parent:
		for child in enemy_spawn_points_parent.get_children():
			if child is Position2D:
				enemy_spawn_points.append(child.global_position)

	# Initialize UI connections (if UI script needs access to Game.gd)
	if game_ui and game_ui.has_method("initialize_ui"):
		game_ui.initialize_ui(player) # Pass player reference

	start_new_game()

func start_new_game():
	current_wave = 0
	king_rat_spawned_this_cycle = false
	game_over_flag = false
	game_paused_for_level_up = false
	
	# Reset player stats/position if needed, or handle in Player._ready()
	# player.reset_stats() 
	
	# Clear existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	
	start_next_wave()
	update_ui()

func _process(delta):
	if game_over_flag or game_paused_for_level_up:
		return

	# Check if all enemies are defeated to start next wave
	var live_enemies = get_tree().get_nodes_in_group("enemies").filter(func(enemy):
		return is_instance_valid(enemy) and enemy.hp > 0
	)
	if live_enemies.size() == 0 and not game_paused_for_level_up and not game_over_flag:
		start_next_wave()
	
	update_ui()

func start_next_wave():
	current_wave += 1
	print("Starting Wave: %s" % current_wave)
	if game_ui and game_ui.has_method("add_combat_log_message"):
		game_ui.add_combat_log_message("Wave %s approaches!" % current_wave, Color.KHAKI)

	var spawn_positions = get_spawn_positions()

	if not king_rat_spawned_this_cycle and current_wave > waves_before_king:
		spawn_enemy(KingRatScene, spawn_positions)
		if game_ui and game_ui.has_method("add_combat_log_message"):
			game_ui.add_combat_log_message("The Royal Rat appears!", Color.ORANGERED)
		king_rat_spawned_this_cycle = true
	else:
		if king_rat_spawned_this_cycle and current_wave > waves_before_king:
			king_rat_spawned_this_cycle = false # Reset for next cycle
		
		var num_rats_to_spawn = 1 + current_wave * 2
		for i in range(num_rats_to_spawn):
			spawn_enemy(RatScene, spawn_positions)

func get_spawn_positions() -> Array:
	# Simple: use predefined spawn points or generate random ones
	# More complex: ensure spawn points are passable on TileMap and away from player
	if not enemy_spawn_points.is_empty():
		return enemy_spawn_points # Use all or pick randomly
	else:
		# Fallback: generate random positions around the player or within map bounds
		var random_positions = []
		var map_rect = tile_map.get_used_rect()
		var cell_size = tile_map.tile_set.tile_size
		for i in range(5): # Generate a few random points
			var rand_x = randi_range(map_rect.position.x, map_rect.end.x -1) * cell_size.x
			var rand_y = randi_range(map_rect.position.y, map_rect.end.y -1) * cell_size.y
			random_positions.append(Vector2(rand_x, rand_y) + tile_map.position)
		return random_positions

func spawn_enemy(enemy_scene: PackedScene, spawn_locations: Array):
	if enemy_scene == null:
		print_error("Enemy scene is null!")
		return
	if spawn_locations.is_empty():
		print_error("No spawn locations provided for enemy!")
		# Fallback: spawn at a default position
		var enemy_instance = enemy_scene.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = player.global_position + Vector2(200, 0).rotated(randf_range(0, TAU))
		enemy_instance.add_to_group("enemies")
		return

	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)
	# Pick a random spawn location
	enemy_instance.global_position = spawn_locations[randi() % spawn_locations.size()]
	enemy_instance.add_to_group("enemies")

func update_ui():
	if game_ui and game_ui.has_method("update_status"):
		game_ui.update_status(player, current_wave)
	# Update enemy UI if needed (e.g. boss health bar)

func _on_player_died(): # Connect this signal from Player.gd if player emits it
	game_over_flag = true
	print("Game Over!")
	if game_ui and game_ui.has_method("show_game_over_screen"):
		game_ui.show_game_over_screen(current_wave, player.level)

func _on_player_level_up(): # Connect from player
	game_paused_for_level_up = true
	# Show power-up selection UI
	if game_ui and game_ui.has_method("present_power_up_choices"):
		var power_ups = get_power_up_options() # Implement this logic
		game_ui.present_power_up_choices(power_ups)

func get_power_up_options() -> Array:
	# This should mirror your ALL_POWER_UPS logic from JS
	# For now, returning a placeholder. You'll need to define these power-ups in Godot.
	var all_power_ups_data = [
		{ "id": "MAX_HP_SMALL", "name": "Toughness I", "description": "+15 Max HP", "apply_func_name": "apply_max_hp_small" },
		{ "id": "MAX_STAMINA_SMALL", "name": "Endurance I", "description": "+20 Max Stamina", "apply_func_name": "apply_max_stamina_small" },
		{ "id": "PROFICIENCY_SMALL", "name": "Swordsmanship I", "description": "+10% Proficiency", "apply_func_name": "apply_proficiency_small" }
	]
	# Shuffle and pick 3 (or fewer if not enough unique ones are left)
	all_power_ups_data.shuffle()
	return all_power_ups_data.slice(0, min(3, all_power_ups_data.size()))

func apply_selected_power_up(power_up_data):
	# Call a method on the player script, or handle directly if power-ups are simple stat boosts
	if player.has_method(power_up_data.apply_func_name):
		player.call(power_up_data.apply_func_name)
		player.acquired_power_ups.append(power_up_data.name)
		print("Applied power-up: %s" % power_up_data.name)
		if game_ui and game_ui.has_method("add_combat_log_message"):
			game_ui.add_combat_log_message("Acquired: %s" % power_up_data.name, Color.AQUAMARINE)
		if game_ui and game_ui.has_method("update_current_powerups_display"):
			game_ui.update_current_powerups_display(player.acquired_power_ups)
	else:
		print_error("Player script does not have method: %s" % power_up_data.apply_func_name)
	
	game_paused_for_level_up = false
	update_ui()

# Placeholder functions for power-ups (these should be in Player.gd or a component)
# This is just to make apply_selected_power_up work. 
# You would define these in Player.gd and call them from there.
func _apply_player_power_up_placeholder(player_node, power_up_id):
	match power_up_id:
		"apply_max_hp_small":
			player_node.max_hp += 15
			player_node.hp += 15
		"apply_max_stamina_small":
			player_node.max_stamina += 20
			player_node.stamina += 20
		"apply_proficiency_small":
			player_node.sword_proficiency = min(1.0, player_node.sword_proficiency + 0.1)

