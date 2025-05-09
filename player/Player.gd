extends CharacterBody2D

# Player stats
var max_hp: int = 100
var hp: int = max_hp
var max_stamina: int = 100
var stamina: int = max_stamina
var sword_proficiency: float = 0.1
var base_sword_damage: int = 10
var base_swing_arc_width: float = PI / 2.2
var base_swing_reach: float = 50.0

var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 30

# Movement
var base_speed: float = 200.0 # pixels/sec
var current_speed: float = base_speed
var dash_speed_multiplier: float = 2.5 # Multiplier of base_speed
var dash_cost: int = 30
var dash_cooldown: float = 1.0 # seconds
var last_dash_time: float = 0.0

# State
var is_running: bool = false
var is_resting: bool = false
var movement_facing_angle: float = 0.0
var attack_facing_angle: float = 0.0

# Power-ups
var acquired_power_ups: Array = []
var aura_heal_amount: int = 0
var aura_heal_interval: float = 2.0 # seconds
var last_aura_heal_time: float = 0.0
var vampiric_heal_percent: float = 0.0
var natural_hp_regen_interval: float = 3.0 # seconds
var base_natural_hp_regen_interval: float = 3.0
var last_natural_heal_time: float = 0.0

# Stamina Regen
var stamina_regen_rate: float = 5.0 # points per second
var base_stamina_regen_rate: float = 5.0

@onready var sprite = $Sprite2D # Assuming you'll add a Sprite2D node
@onready var animation_player = $AnimationPlayer # If you add an AnimationPlayer
@onready var sword_area = $SwordArea/CollisionShape2D # Assuming an Area2D for sword swings

func _ready():
	hp = max_hp
	stamina = max_stamina
	# Connect signals, initialize other things

func _physics_process(delta):
	handle_input(delta)
	move_and_slide()
	regenerate_stamina(delta)
	apply_passive_effects(delta)
	update_facing_direction()

func handle_input(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	is_running = Input.is_action_pressed("run")
	
	if Input.is_action_just_pressed("dash"):
		try_dash()
	
	if Input.is_action_just_pressed("rest"):
		toggle_rest()

	if is_resting:
		velocity = Vector2.ZERO
		return

	current_speed = base_speed * (2.0 if is_running else 1.0)
	velocity = direction.normalized() * current_speed

	if direction != Vector2.ZERO:
		movement_facing_angle = velocity.angle()
		# Update sprite animation if you have one
		# sprite.flip_h = velocity.x < 0 # Example for 2D sprite flipping

func update_facing_direction():
	var mouse_pos = get_global_mouse_position()
	attack_facing_angle = global_position.direction_to(mouse_pos).angle()
	# Potentially rotate a part of the sprite or a weapon node towards mouse

func try_dash():
	if stamina >= dash_cost and Time.get_ticks_msec() / 1000.0 > last_dash_time + dash_cooldown:
		stamina -= dash_cost
		last_dash_time = Time.get_ticks_msec() / 1000.0
		# Implement dash movement (e.g., a short burst of speed or a teleport)
		var dash_vector = Vector2.RIGHT.rotated(attack_facing_angle) # Dash towards mouse initially
		if velocity != Vector2.ZERO: # Or dash in movement direction if moving
			dash_vector = velocity.normalized()
		
		# This is a simple dash. A more robust one would use a tween or a temporary state.
		var dash_tween = get_tree().create_tween()
		var target_position = global_position + dash_vector * base_speed * dash_speed_multiplier * 0.2 # Dash for 0.2 seconds
		# Check for collisions before dashing, or use test_move for safety
		dash_tween.tween_property(self, "global_position", target_position, 0.1).set_trans(Tween.TRANS_LINEAR)
		print("Dashed!") # Replace with sound/animation
	elif stamina < dash_cost:
		print("Not enough stamina for dash!")
	else:
		print("Dash on cooldown!")

func toggle_rest():
	is_resting = !is_resting
	if is_resting:
		print("Resting...")
		# Stop movement, play rest animation
	else:
		print("Stopped resting.")

func regenerate_stamina(delta):
	var current_regen_rate = base_stamina_regen_rate
	if is_resting:
		current_regen_rate *= 5.0
	elif velocity != Vector2.ZERO: # No regen while moving/running unless specific powerup
		return

	if stamina < max_stamina:
		stamina = min(max_stamina, stamina + current_regen_rate * delta)

func apply_passive_effects(delta):
	# Aura Heal
	if aura_heal_amount > 0 and Time.get_ticks_msec() / 1000.0 > last_aura_heal_time + aura_heal_interval:
		if hp < max_hp:
			hp = min(max_hp, hp + aura_heal_amount)
			print("Aura heals %s HP." % aura_heal_amount) # Connect to UI
		last_aura_heal_time = Time.get_ticks_msec() / 1000.0
	
	# Natural HP Regen
	var current_hp_regen_interval = base_natural_hp_regen_interval
	if is_resting:
		current_hp_regen_interval /= 3.0
	
	if Time.get_ticks_msec() / 1000.0 > last_natural_heal_time + current_hp_regen_interval:
		if hp < max_hp:
			hp = min(max_hp, hp + 1) # Heal 1 HP
		last_natural_heal_time = Time.get_ticks_msec() / 1000.0

func take_damage(amount):
	hp -= amount
	print("Player took %s damage. HP: %s/%s" % [amount, hp, max_hp]) # Connect to UI
	if hp <= 0:
		hp = 0
		die()

func die():
	print("Player died!")
	# Handle game over: show game over screen, stop game, etc.
	# get_tree().change_scene_to_file("res://ui/GameOverScreen.tscn") # Example
	set_physics_process(false) # Stop processing player

func attack():
	if stamina >= 5: # Example attack stamina cost
		stamina -= 5
		print("Player attacks!")
		# Enable sword_area collision shape for a short duration
		# Or play an animation that triggers the hitbox
		if sword_area:
			sword_area.disabled = false
			var attack_timer = get_tree().create_timer(0.2) # Swing duration
			await attack_timer.timeout
			if sword_area: # Check if still valid
				sword_area.disabled = true
	else:
		print("Not enough stamina to attack!")

func _on_sword_area_body_entered(body): # Connect this signal from SwordArea
	if body.has_method("take_damage"): # Check if the body is an enemy
		var damage = base_sword_damage # Add proficiency bonus etc.
		body.take_damage(damage)
		print("Hit %s for %s damage" % [body.name, damage])
		
		if vampiric_heal_percent > 0 and hp < max_hp:
			var heal_amount = ceil(damage * vampiric_heal_percent)
			if heal_amount > 0:
				hp = min(max_hp, hp + heal_amount)
				print("Vampiric strike heals %s HP." % heal_amount)


func gain_xp(amount):
	xp += amount
	print("Gained %s XP. Total XP: %s/%s" % [amount, xp, xp_to_next_level])
	if xp >= xp_to_next_level:
		level_up()

func level_up():
	level += 1
	xp -= xp_to_next_level
	if xp < 0: xp = 0
	# Calculate next xp_to_next_level based on your formula
	xp_to_next_level = int(xp_to_next_level * 1.45) 
	
	hp = max_hp # Full heal on level up
	stamina = max_stamina # Full stamina refill
	
	print("Level Up! Reached Level %s!" % level)
	# Trigger power-up selection UI
	# GameManager.present_power_up_choices() (if using an autoloaded GameManager)

# Define input actions in Project > Project Settings > Input Map
# e.g., "move_left", "move_right", "move_up", "move_down", "dash", "run", "attack", "rest"
