extends CharacterBody2D

signal defeated

const SPEED := 115.0
const GRAVITY := 1650.0
const MAX_HEALTH := 5
const DETECT_RANGE := 560.0
const ATTACK_RANGE := 76.0
const ATTACK_WINDUP := 0.42
const ATTACK_COOLDOWN := 1.25

var health := MAX_HEALTH
var player: CharacterBody2D
var attack_cooldown := 0.7
var windup_timer := 0.0
var hit_stun_timer := 0.0
var dead := false
var attack_direction := 1.0
var health_bar: ProgressBar

@onready var body_visual: Polygon2D = $Body

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(-29, -88)
	health_bar.size = Vector2(58, 7)
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	health_bar.show_percentage = false
	add_child(health_bar)

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if hit_stun_timer > 0.0:
		hit_stun_timer = maxf(0.0, hit_stun_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 2.0 * delta)
		move_and_slide()
		return

	if windup_timer > 0.0:
		windup_timer = maxf(0.0, windup_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)
		if windup_timer <= 0.0:
			_perform_attack()
		move_and_slide()
		return

	if is_instance_valid(player) and not player.get("dead"):
		var distance := player.global_position.x - global_position.x
		if absf(distance) < DETECT_RANGE and absf(distance) > ATTACK_RANGE:
			velocity.x = signf(distance) * SPEED
			attack_direction = signf(distance)
			body_visual.scale.x = attack_direction
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
		if absf(distance) <= ATTACK_RANGE and attack_cooldown <= 0.0:
			attack_direction = signf(distance) if distance != 0.0 else 1.0
			body_visual.scale.x = attack_direction
			attack_cooldown = ATTACK_COOLDOWN
			windup_timer = ATTACK_WINDUP
			body_visual.modulate = Color(1.0, 0.72, 0.28, 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
	move_and_slide()

func _perform_attack() -> void:
	if dead:
		return
	body_visual.modulate = Color(1.0, 0.25, 0.18, 1.0)
	if is_instance_valid(player) and not player.get("dead"):
		var distance := absf(player.global_position.x - global_position.x)
		if distance <= ATTACK_RANGE + 24.0 and player.has_method("take_damage"):
			player.take_damage(1, Vector2(attack_direction * 390.0, -260.0))
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(self) and not dead and hit_stun_timer <= 0.0:
		body_visual.modulate = Color.WHITE

func take_hit(damage: int, knockback: Vector2) -> void:
	if dead:
		return
	health = maxi(0, health - damage)
	health_bar.value = health
	velocity = knockback
	hit_stun_timer = 0.18
	body_visual.modulate = Color(1.0, 0.42, 0.32, 1.0)
	if health <= 0:
		dead = true
		defeated.emit()
		queue_free()
		return
	await get_tree().create_timer(0.14).timeout
	if is_instance_valid(self) and not dead and windup_timer <= 0.0:
		body_visual.modulate = Color.WHITE
