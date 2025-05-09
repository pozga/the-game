extends CharacterBody2D

# Enemy Stats
var max_hp: int = 25
var hp: int = max_hp
var attack_damage: int = 3
var speed: float = 100.0
var xp_value: int = 10

# AI State
enum State { IDLE, CHASING, ATTACKING, FLEEING, DEAD }
var current_state: State = State.IDLE

var detection_range: float = 150.0
var attack_range: float = 30.0 # Distance from player to start attacking
var attack_cooldown: float = 1.8 # seconds
var last_attack_time: float = 0.0
var flee_threshold: float = 0.3 # Flee if HP is below 30% of max_hp

# Wander
var wander_target_position: Vector2
var wander_timer: Timer

# Target (Player)
var player_node: Node2D = null

@onready var sprite = $Sprite2D # Assuming a Sprite2D child
# @onready var animation_player = $AnimationPlayer # If you have animations

func _ready():
	hp = max_hp
	wander_timer = Timer.new()
	wander_timer.wait_time = randf_range(3.0, 6.0)
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)
	wander_timer.start()
	_set_new_wander_target()

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Try to find the player if not already found (can be optimized)
	if not is_instance_valid(player_node):
		# This is a simple way; a better way might be using groups or Area2D for detection
		player_node = get_tree().get_first_node_in_group("player") 

	if is_instance_valid(player_node):
		var distance_to_player = global_position.distance_to(player_node.global_position)
		
		# State transitions
		if hp <= 0:
			set_state(State.DEAD)
		elif hp / float(max_hp) < flee_threshold:
			set_state(State.FLEEING)
		elif distance_to_player <= attack_range and player_node.hp > 0:
			set_state(State.ATTACKING)
		elif distance_to_player <= detection_range and player_node.hp > 0 and not player_node.is_resting:
			set_state(State.CHASING)
		else:
			set_state(State.IDLE)
	else:
		# Player not found, default to IDLE
		set_state(State.IDLE)
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.CHASING:
			_state_chasing(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.FLEEING:
			_state_fleeing(delta)
	
	move_and_slide()

func set_state(new_state: State):
	if current_state != new_state:
		current_state = new_state
		# print("%s new state: %s" % [name, State.keys()[new_state]])
		match current_state:
			State.IDLE:
				wander_timer.start()
			State.CHASING:
				wander_timer.stop()
			State.ATTACKING:
				wander_timer.stop()
			State.FLEEING:
				wander_timer.stop()
			State.DEAD:
				_die()

func _state_idle(delta):
	var direction_to_wander_target = global_position.direction_to(wander_target_position)
	if global_position.distance_squared_to(wander_target_position) > 100: # Don't need to be exact
		velocity = direction_to_wander_target * speed * 0.3 # Wander slower
	else:
		velocity = Vector2.ZERO
		_set_new_wander_target() # Arrived, pick new target

func _state_chasing(delta):
	if is_instance_valid(player_node):
		var direction_to_player = global_position.direction_to(player_node.global_position)
		velocity = direction_to_player * speed
	else:
		velocity = Vector2.ZERO

func _state_attacking(delta):
	velocity = Vector2.ZERO # Stop to attack
	if is_instance_valid(player_node) and Time.get_ticks_msec() / 1000.0 > last_attack_time + attack_cooldown:
		print("%s attacks!" % name)
		player_node.take_damage(attack_damage)
		last_attack_time = Time.get_ticks_msec() / 1000.0
		# Add attack animation/sound here

func _state_fleeing(delta):
	if is_instance_valid(player_node):
		var direction_away_from_player = global_position.direction_to(player_node.global_position) * -1
		velocity = direction_away_from_player * speed * 1.2 # Flee faster
	else:
		set_state(State.IDLE) # No player to flee from

func _set_new_wander_target():
	# Wander within a certain radius of the enemy's starting position or current position
	var wander_radius = 200.0
	wander_target_position = global_position + Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	# Optional: Clamp to map bounds if needed
	wander_timer.start()

func _on_wander_timer_timeout():
	if current_state == State.IDLE:
		_set_new_wander_target()

func take_damage(amount: int):
	hp -= amount
	print("%s took %s damage. HP: %s/%s" % [name, amount, hp, max_hp])
	if hp <= 0 and current_state != State.DEAD:
		set_state(State.DEAD)
	# else:
		# Play hurt animation/sound

func _die():
	print("%s defeated!" % name)
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	# Grant XP to player
	if is_instance_valid(player_node):
		if player_node.has_method("gain_xp"):
			player_node.gain_xp(xp_value)
	
	# Optional: Start a death animation, then queue_free()
	queue_free()

# Add this enemy to a group named "enemies" in the editor for easy access
