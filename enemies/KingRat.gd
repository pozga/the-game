extends "res://enemies/Rat.gd"

# King Rat specific stats (override Rat.gd)
var can_spawn_minions: bool = true
var spawn_minion_cooldown: float = 15.0 # seconds
var last_minion_spawn_time: float = -15.0 # Allow first spawn early
var max_minions_allowed: int = 8
var minions_to_spawn: int = 2

# Reference to the Rat scene for spawning
const MinionRatScene = preload("res://enemies/Rat.tscn")

func _ready():
	super() # Call the parent Rat class's _ready function
	name = "KingRat" # Or set in scene
	max_hp = 150
	hp = max_hp
	attack_damage = 10
	speed = 80.0
	xp_value = 100
	detection_range = 200.0
	attack_range = 40.0
	attack_cooldown = 1.5
	flee_threshold = 0.1 # King Rat flees later or not at all?

func _physics_process(delta):
	super(delta) # Call parent Rat class's _physics_process

	if current_state != State.DEAD and can_spawn_minions:
		if Time.get_ticks_msec() / 1000.0 > last_minion_spawn_time + spawn_minion_cooldown:
			# Check current minion count (requires a way to count minions, e.g. group)
			var current_minions = get_tree().get_nodes_in_group("enemies").filter(func(enemy):
				return enemy.name != "KingRat" and is_instance_valid(enemy) and enemy.hp > 0
			).size()

			if current_minions < max_minions_allowed:
				spawn_minions()
				last_minion_spawn_time = Time.get_ticks_msec() / 1000.0

func spawn_minions():
	print("King Rat summons minions!")
	for i in range(minions_to_spawn):
		var minion = MinionRatScene.instantiate()
		# Get the parent node where enemies are spawned (e.g., the main game scene)
		var spawn_parent = get_parent() 
		if spawn_parent:
			# Spawn near the King Rat
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			minion.global_position = global_position + offset
			spawn_parent.add_child(minion)
			minion.add_to_group("enemies") # Ensure spawned minions are also in the group
		else:
			print_error("KingRat cannot find spawn parent for minions!")

# Override die if King Rat has special death behavior
# func _die():
# 	super()
# 	print("The King Rat has fallen!")
# 	# Maybe trigger something in the game (e.g. next level, special drop)
