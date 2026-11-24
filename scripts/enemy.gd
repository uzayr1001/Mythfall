extends CharacterBody2D

const SPEED := 115.0
const GRAVITY := 1650.0
const MAX_HEALTH := 3
const DETECT_RANGE := 520.0
const ATTACK_RANGE := 74.0
const ATTACK_WINDUP := 0.30
const ATTACK_COOLDOWN := 1.15
const HIT_STUN_TIME := 0.16

var health := MAX_HEALTH
var player: CharacterBody2D
var attack_cooldown := 0.45
var windup_timer := 0.0
var hit_stun_timer := 0.0
var dead := false
var attack_direction := 1.0

@onready var body_visual: Polygon2D = $Body

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

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
		var absolute_distance := absf(distance)
		if absolute_distance < DETECT_RANGE and absolute_distance > ATTACK_RANGE:
			velocity.x = signf(distance) * SPEED
			attack_direction = signf(distance)
			body_visual.scale.x = attack_direction
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)

		if absolute_distance <= ATTACK_RANGE and attack_cooldown <= 0.0:
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
	body_visual.modulate = Color(1.0, 0.35, 0.24, 1.0)
	if is_instance_valid(player) and not player.get("dead"):
		var distance := absf(player.global_position.x - global_position.x)
		if distance <= ATTACK_RANGE + 18.0 and player.has_method("take_damage"):
			player.take_damage(1, Vector2(attack_direction * 360.0, -250.0))
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not dead:
		body_visual.modulate = Color.WHITE

func take_hit(damage: int, knockback: Vector2) -> void:
	if dead:
		return
	health = maxi(0, health - damage)
	velocity = knockback
	hit_stun_timer = HIT_STUN_TIME
	body_visual.modulate = Color(1.0, 0.5, 0.5, 1.0)
	if health <= 0:
		dead = true
		queue_free()
		return
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not dead and windup_timer <= 0.0:
		body_visual.modulate = Color.WHITE
