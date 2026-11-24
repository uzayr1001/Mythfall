extends CharacterBody2D

const SPEED := 115.0
const GRAVITY := 1650.0
const MAX_HEALTH := 3

var health := MAX_HEALTH
var player: CharacterBody2D
var attack_cooldown := 0.0
var dead := false

@onready var body_visual: Polygon2D = $Body

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_instance_valid(player) and not player.get("dead"):
		var distance := player.global_position.x - global_position.x
		if absf(distance) < 520.0 and absf(distance) > 42.0:
			velocity.x = signf(distance) * SPEED
			body_visual.scale.x = signf(distance)
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
		if absf(distance) < 55.0 and attack_cooldown <= 0.0:
			attack_cooldown = 1.0
			if player.has_method("take_damage"):
				player.take_damage(1, Vector2(signf(distance) * 360.0, -250.0))
	move_and_slide()

func take_hit(damage: int, knockback: Vector2) -> void:
	if dead:
		return
	health -= damage
	velocity = knockback
	modulate = Color(1.0, 0.5, 0.5, 1.0)
	if health <= 0:
		dead = true
		queue_free()
		return
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self):
		modulate = Color.WHITE
