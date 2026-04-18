extends CharacterBody2D

# ====== MOVEMENT CONFIG ======
@export var speed = 200
@export var jump_force = -400
@export var gravity = 900

# ====== STATE ======
var is_jumping = false

var enemy_in_range = false

# ====== ANIMATION ======
@onready var anim = $AnimatedSprite2D

# ====== LOGIC SYSTEM (awal sederhana) ======
var rules = [
	{"if": "enemy_near", "do": "attack"}
]


func _physics_process(delta):
	handle_movement(delta)
	process_rules()
	update_animation()

# ==============================
# MOVEMENT (Dead Cells feel lite)
# ==============================
func handle_movement(delta):
	# Auto-run ke kanan
	velocity.x = speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump (manual biar tetap ada skill)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		is_jumping = true

	move_and_slide()

# ==============================
# ANIMATION
# ==============================
func update_animation():
	if not is_on_floor():
		anim.play("jump")
	elif velocity.x != 0:
		anim.play("run")
	else:
		anim.play("idle")

# ==============================
# LOGIC SYSTEM (ciri khas game kamu)
# ==============================
func process_rules():
	for rule in rules:
		if check_condition(rule["if"]):
			do_action(rule["do"])

# ==============================
# CONDITIONS
# ==============================
func check_condition(cond):
	match cond:
		"enemy_near":
			return is_enemy_near()
	return false

# ==============================
# ACTIONS
# ==============================
func do_action(action):
	match action:
		"attack":
			attack()

# ==============================
# DUMMY SYSTEM (sementara)
# ==============================
func is_enemy_near():
	return enemy_in_range

func attack():
	print("attack triggered!")



func _on_EnemyDetector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemy_in_range = true
		print("ENTERED:", body.name)


func _on_EnemyDetector_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemy_in_range = false
		print("ENTERED:", body.name)
