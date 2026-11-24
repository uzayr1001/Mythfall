extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal player_died

const SPEED := 340.0
const GROUND_ACCEL := 2200.0
const AIR_ACCEL := 1250.0
const JUMP_VELOCITY := -650.0
const GRAVITY := 1650.0
const DASH_SPEED := 900.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.62
const MAX_HEALTH := 3
const COMBO_WINDOW := 0.72
const COMBO_DAMAGE := [1, 1, 2]
const COMBO_KNOCKBACK := [470.0, 560.0, 760.0]

var health := MAX_HEALTH
var facing := 1
var jumps_left := 2
var dash_timer := 0.0
var dash_cooldown := 0.0
var combo_timer := 0.0
var combo_step := 0
var attacking := false
var invulnerable := false
var dead := false
var hit_targets: Array[Node2D] = []

@onready var body_visual: Polygon2D = $Body
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.monitoring = false
	health_changed.emit(health, MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if dead:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return

	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0 and not attacking:
		combo_step = 0
	if is_on_floor():
		jumps_left = 2

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		body_visual.scale.x = facing

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY if jumps_left == 2 else JUMP_VELOCITY * 0.88
		jumps_left -= 1

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_timer = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		invulnerable = true
		velocity = Vector2(facing * DASH_SPEED, 0.0)

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity.x = facing * DASH_SPEED
		if dash_timer <= 0.0:
			invulnerable = false
	else:
		var acceleration := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("attack") and not attacking:
		_start_attack()

	move_and_slide()

func _start_attack() -> void:
	if combo_timer <= 0.0:
		combo_step = 0
	var step := combo_step
	combo_step = (combo_step + 1) % 3
	combo_timer = COMBO_WINDOW
	attacking = true
	hit_targets.clear()
	attack_area.position.x = 46.0 * facing
	attack_area.position.y = -34.0
	body_visual.modulate = [Color(1.0, 0.92, 0.72), Color(0.72, 0.94, 1.0), Color(1.0, 0.62, 0.42)][step]
	_spawn_slash(step)
	await get_tree().create_timer(0.075).timeout
	if not is_instance_valid(self):
		return
	attack_area.monitoring = true
	await get_tree().create_timer(0.105).timeout
	if not is_instance_valid(self):
		return
	attack_area.monitoring = false
	attacking = false
	if not invulnerable and not dead:
		body_visual.modulate = Color.WHITE

func _spawn_slash(step: int) -> void:
	var slash := Polygon2D.new()
	slash.polygon = PackedVector2Array([-8, -10, 22, -42, 82, -50, 48, -18, 78, 0, 24, -4])
	slash.color = [Color(1.0, 0.78, 0.42, 0.9), Color(0.55, 0.88, 1.0, 0.9), Color(1.0, 0.42, 0.22, 0.95)][step]
	slash.position = Vector2(14.0 * facing, -34.0)
	slash.scale.x = facing
	add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(slash, "scale", Vector2(1.25 * facing, 1.25), 0.18)
	tween.tween_callback(slash.queue_free)

func take_damage(amount: int, knockback: Vector2) -> void:
	if invulnerable or dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	velocity = knockback
	invulnerable = true
	modulate = Color(1.0, 0.35, 0.35, 1.0)
	await get_tree().create_timer(0.72).timeout
	if not is_instance_valid(self):
		return
	modulate = Color.WHITE
	invulnerable = false
	if health <= 0:
		dead = true
		player_died.emit()

func _on_attack_area_body_entered(target: Node2D) -> void:
	if target in hit_targets:
		return
	if target.is_in_group("enemy") and target.has_method("take_hit"):
		hit_targets.append(target)
		target.take_hit(COMBO_DAMAGE[(combo_step + 2) % 3], Vector2(facing * COMBO_KNOCKBACK[(combo_step + 2) % 3], -180.0))
