extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal player_died

const SPEED := 340.0
const GROUND_ACCEL := 2200.0
const AIR_ACCEL := 1250.0
const JUMP_VELOCITY := -650.0
const GRAVITY := 1650.0
const DASH_SPEED := 900.0
const DASH_TIME := 0.17
const DASH_COOLDOWN := 0.58
const MAX_HEALTH := 3
const COMBO_RESET_TIME := 0.82

var health := MAX_HEALTH
var facing := 1
var jumps_left := 2
var dash_timer := 0.0
var dash_cooldown := 0.0
var attack_cooldown := 0.0
var combo_timer := 0.0
var combo_step := 0
var attacking := false
var invulnerable := false
var dead := false
var hit_targets: Array[Node2D] = []

@onready var body_visual: Polygon2D = $Body
@onready var attack_area: Area2D = $AttackArea
@onready var slash: Polygon2D = $Slash

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	health_changed.emit(health, MAX_HEALTH)
	slash.visible = false

func _physics_process(delta: float) -> void:
	if dead:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return

	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo_step = 0
	if is_on_floor():
		jumps_left = 2

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		body_visual.scale.x = facing
		slash.scale.x = facing
		attack_area.position.x = 42.0 * facing

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY if jumps_left == 2 else JUMP_VELOCITY * 0.88
		jumps_left -= 1

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_timer = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		velocity = Vector2(facing * DASH_SPEED, 0.0)

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity.x = facing * DASH_SPEED
	else:
		var acceleration := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and not attacking:
		_start_attack()

	move_and_slide()

func _start_attack() -> void:
	attacking = true
	attack_cooldown = 0.22
	combo_timer = COMBO_RESET_TIME
	combo_step = (combo_step % 3) + 1
	hit_targets.clear()

	var damage := 2 if combo_step == 3 else 1
	attack_area.position.x = 42.0 * facing
	attack_area.monitoring = true
	slash.visible = true
	slash.modulate = Color(1.0, 0.88, 0.58, 1.0)
	slash.rotation = -0.32 if facing > 0 else 0.32
	var slash_tween := create_tween()
	slash_tween.set_parallel(true)
	slash_tween.tween_property(slash, "rotation", 0.48 if facing > 0 else -0.48, 0.16)
	slash_tween.tween_property(slash, "modulate:a", 0.0, 0.16)
	body_visual.modulate = Color(1.0, 0.9, 0.7, 1.0)

	await get_tree().physics_frame
	if not is_instance_valid(self):
		return
	for target in attack_area.get_overlapping_bodies():
		_apply_attack_to(target, damage)

	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self):
		return
	attack_area.monitoring = false
	attacking = false
	slash.visible = false
	slash.modulate.a = 1.0
	if not invulnerable and not dead:
		body_visual.modulate = Color.WHITE

func _apply_attack_to(target: Node2D, damage: int) -> void:
	if target in hit_targets:
		return
	if target.is_in_group("enemy") and target.has_method("take_hit"):
		hit_targets.append(target)
		target.take_hit(damage, Vector2(facing * (420.0 + combo_step * 55.0), -190.0))

func take_damage(amount: int, knockback: Vector2) -> void:
	if invulnerable or dash_timer > 0.0 or dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	velocity = knockback
	invulnerable = true
	modulate = Color(1.0, 0.38, 0.38, 1.0)
	await get_tree().create_timer(0.72).timeout
	if not is_instance_valid(self):
		return
	modulate = Color.WHITE
	invulnerable = false
	if health <= 0:
		dead = true
		player_died.emit()

func _on_attack_area_body_entered(target: Node2D) -> void:
	_apply_attack_to(target, 2 if combo_step == 3 else 1)
