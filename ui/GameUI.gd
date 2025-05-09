extends CanvasLayer

# --- Player Status UI ---
@onready var player_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/PlayerStatusBox/HBoxContainer/PlayerHPBar
@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/HBoxContainer/PlayerHPLabel
@onready var player_stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/PlayerStatusBox/HBoxContainer2/PlayerStaminaBar
@onready var player_stamina_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/HBoxContainer2/PlayerStaminaLabel
@onready var player_level_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/PlayerLevelLabel
@onready var player_xp_bar: ProgressBar = $MarginContainer/VBoxContainer/PlayerStatusBox/PlayerXPBar
@onready var player_xp_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/PlayerXPLabel
@onready var proficiency_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/ProficiencyLabel
@onready var player_status_text_label: Label = $MarginContainer/VBoxContainer/PlayerStatusBox/PlayerStatusTextLabel

# --- Enemy Status UI ---
@onready var enemy_status_box: PanelContainer = $MarginContainer/VBoxContainer/EnemyStatusBox
@onready var enemy_name_label: Label = $MarginContainer/VBoxContainer/EnemyStatusBox/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/EnemyStatusBox/VBoxContainer/EnemyHPBar
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/EnemyStatusBox/VBoxContainer/EnemyHPLabel
@onready var enemy_flavor_text_label: Label = $MarginContainer/VBoxContainer/EnemyStatusBox/VBoxContainer/EnemyFlavorTextLabel

# --- Combat Log --- 
@onready var combat_log_richtext: RichTextLabel = $MarginContainer/VBoxContainer/CombatLogPanel/CombatLogRichText

# --- Wave Info ---
@onready var wave_info_label: Label = $MarginContainer/VBoxContainer/WaveInfoLabel

# --- Power-up Selection ---
@onready var powerup_selection_panel: PanelContainer = $PowerUpSelectionPanel
@onready var powerup_options_container: VBoxContainer = $PowerUpSelectionPanel/MarginContainer/VBoxContainer/PowerUpOptionsContainer
@onready var powerup_choice_button_scene = preload("res://ui/PowerUpChoiceButton.tscn") # We'll create this small scene too

# --- Current Power-ups ---
@onready var current_powerups_list_label: Label = $MarginContainer/VBoxContainer/CurrentPowerUpsPanel/CurrentPowerUpsListLabel

# --- Game Over Screen ---
@onready var game_over_screen: PanelContainer = $GameOverScreen
@onready var game_over_wave_label: Label = $GameOverScreen/MarginContainer/VBoxContainer/WaveSurvivedLabel
@onready var game_over_level_label: Label = $GameOverScreen/MarginContainer/VBoxContainer/LevelReachedLabel

var player_ref # Reference to the player node
var game_manager_ref # Reference to Game.gd or GameManager autoload

func _ready():
	powerup_selection_panel.hide()
	enemy_status_box.hide()
	game_over_screen.hide()

func initialize_ui(player_node, game_node = null):
	player_ref = player_node
	game_manager_ref = game_node # If Game.gd handles powerup logic directly
	# Connect signals from player if not done in editor
	# player_ref.connect("hp_changed", Callable(self, "update_player_hp"))
	# player_ref.connect("stamina_changed", Callable(self, "update_player_stamina"))
	# ... and so on for other stats

func update_status(player_data, current_wave_num):
	if not is_instance_valid(player_data):
		return

	# Player Stats
	player_hp_bar.max_value = player_data.max_hp
	player_hp_bar.value = player_data.hp
	player_hp_label.text = "HP: %s/%s" % [player_data.hp, player_data.max_hp]

	player_stamina_bar.max_value = player_data.max_stamina
	player_stamina_bar.value = player_data.stamina
	player_stamina_label.text = "Stamina: %s/%s" % [int(player_data.stamina), player_data.max_stamina]

	player_level_label.text = "Level: %s" % player_data.level
	player_xp_bar.max_value = player_data.xp_to_next_level
	player_xp_bar.value = player_data.xp
	player_xp_label.text = "XP: %s/%s" % [player_data.xp, player_data.xp_to_next_level]

	proficiency_label.text = "Proficiency: %s%%" % int(player_data.sword_proficiency * 100)

	if player_data.is_resting:
		player_status_text_label.text = "Resting..."
	elif player_data.is_running:
		player_status_text_label.text = "Running!"
	else:
		player_status_text_label.text = ""

	# Wave Info
	wave_info_label.text = "Wave: %s" % current_wave_num

	# Enemy Status (find closest or most relevant enemy)
	# This part needs logic from Game.gd or a signal to know which enemy to display
	# For now, we'll assume Game.gd calls a specific function if an enemy is targeted

func update_target_enemy_status(enemy_data):
	if not is_instance_valid(enemy_data) or enemy_data.hp <= 0:
		enemy_status_box.hide()
		return
	
	enemy_status_box.show()
	enemy_name_label.text = "Opponent: %s" % enemy_data.name # Or enemy_data.type
	enemy_hp_bar.max_value = enemy_data.max_hp
	enemy_hp_bar.value = enemy_data.hp
	enemy_hp_label.text = "HP: %s/%s" % [int(enemy_data.hp), enemy_data.max_hp]
	# enemy_flavor_text_label.text = enemy_data.get_flavor_text() # if you add such a method

func add_combat_log_message(message: String, color: Color = Color.WHITE):
	combat_log_richtext.add_text("[color=%s]%s[/color]
" % [color.to_html(false), message])
	# Autoscroll to bottom
	combat_log_richtext.scroll_to_line(combat_log_richtext.get_line_count() -1)
	# Limit log lines
	# var max_lines = 15
	# if combat_log_richtext.get_line_count() > max_lines:
		# combat_log_richtext.remove_line(0)

func present_power_up_choices(power_ups_array: Array):
	# Clear previous options
	for child in powerup_options_container.get_children():
		child.queue_free()

	if power_ups_array.is_empty():
		add_combat_log_message("No new power-ups available.", Color.ORANGE)
		# game_manager_ref.apply_selected_power_up(null) # Tell game manager to resume
		powerup_selection_panel.hide()
		return

	for power_up_data in power_ups_array:
		var choice_button = powerup_choice_button_scene.instantiate()
		choice_button.get_node("Button").text = "%s (%s)" % [power_up_data.name, power_up_data.description]
		# Connect button press to a method in this script, then call Game.gd
		choice_button.get_node("Button").pressed.connect(_on_power_up_selected.bind(power_up_data))
		powerup_options_container.add_child(choice_button)
	
powerup_selection_panel.show()

func _on_power_up_selected(power_up_data):
	powerup_selection_panel.hide()
	# Clear options again
	for child in powerup_options_container.get_children():
		child.queue_free()

	if game_manager_ref and game_manager_ref.has_method("apply_selected_power_up"):
		game_manager_ref.apply_selected_power_up(power_up_data)
	else:
		print_error("Game manager reference not set or method not found for power-up application.")

func update_current_powerups_display(acquired_powerups_names: Array):
	if acquired_powerups_names.is_empty():
		current_powerups_list_label.text = "Acquired Power-ups:
- None yet..."
	else:
		var text = "Acquired Power-ups:
"
		for pu_name in acquired_powerups_names:
			text += "- %s
" % pu_name
		current_powerups_list_label.text = text

func show_game_over_screen(wave_reached: int, level_reached: int):
	game_over_wave_label.text = "Survived: Wave %s" % wave_reached
	game_over_level_label.text = "Level Reached: %s" % level_reached
	game_over_screen.show()

func _on_restart_button_pressed(): # Connect this to your Restart button in GameOverScreen
	game_over_screen.hide()
	get_tree().reload_current_scene() # Simple restart
	# Or call a method in Game.gd to properly reset the game state
	# if game_manager_ref and game_manager_ref.has_method("start_new_game"):
	# 	game_manager_ref.start_new_game()
