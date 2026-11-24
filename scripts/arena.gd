extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@onready var player: CharacterBody2D = $Player
@onready var health_label: Label = $CanvasLayer/HUD/Health
@onready var result_label: Label = $CanvasLayer/HUD/Result
@onready var wave_label: Label = $CanvasLayer/HUD/Wave
@onready var kills_label: Label = $CanvasLayer/HUD/Kills
@onready var status_label: Label = $CanvasLayer/HUD/Status

var wave := 1
var kills := 0
var changing_wave := false

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.player_died.connect(_on_player_died)
	_on_health_changed(3, 3)
	_update_run_hud()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_connect_enemy(enemy)
	status_label.text = "THE ASH HOUNDS ARE DRAWN TO YOUR LIGHT"

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.035, 0.025, 0.055, 1.0))
	for i in range(92):
		var x := fmod(float(i * 197 + 41), 1280.0)
		var y := fmod(float(i * 83 + 19), 540.0)
		var radius := 1.0 if i % 5 != 0 else 2.0
		draw_circle(Vector2(x, y), radius, Color(0.72, 0.62, 0.76, 0.22))
	draw_rect(Rect2(0, 510, 1280, 140), Color(0.075, 0.055, 0.105, 0.92))
	draw_rect(Rect2(0, 632, 1280, 88), Color(0.17, 0.12, 0.20, 1.0))
	draw_line(Vector2(0, 632), Vector2(1280, 632), Color(0.74, 0.39, 0.47, 0.8), 3.0)
	for x in [92.0, 1188.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 32, 632), Vector2(x - 23, 300), Vector2(x, 252), Vector2(x + 23, 300), Vector2(x + 32, 632)]), Color(0.11, 0.075, 0.14, 0.92))
		draw_line(Vector2(x, 330), Vector2(x, 600), Color(0.45, 0.25, 0.42, 0.28), 2.0)
	for x in range(40, 1280, 80):
		draw_line(Vector2(x, 650), Vector2(x + 26, 650), Color(0.7, 0.42, 0.52, 0.18), 2.0)

func _connect_enemy(enemy: Node) -> void:
	if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	kills += 1
	_update_run_hud()
	if get_tree().get_nodes_in_group("enemy").size() <= 1 and not changing_wave:
		_advance_wave()

func _advance_wave() -> void:
	changing_wave = true
	status_label.text = "AREA CLEARED  /  PREPARE FOR THE NEXT WAVE"
	await get_tree().create_timer(1.45).timeout
	if not is_instance_valid(self) or player.dead:
		return
	wave += 1
	_update_run_hud()
	status_label.text = "WAVE %02d  /  THE HUNT CONTINUES" % wave
	var enemy_count := mini(1 + wave, 4)
	for index in range(enemy_count):
		var enemy := ENEMY_SCENE.instantiate()
		var spawn_x := 170.0 if index % 2 == 0 else 1110.0
		if enemy_count > 2 and index >= 2:
			spawn_x = 360.0 if index == 2 else 920.0
		enemy.position = Vector2(spawn_x, 570)
		add_child(enemy)
		_connect_enemy(enemy)
	changing_wave = false

func _update_run_hud() -> void:
	wave_label.text = "WAVE  %02d" % wave
	kills_label.text = "KILLS  %03d" % kills

func _on_health_changed(current_health: int, max_health: int) -> void:
	var hearts := ""
	for index in range(max_health):
		hearts += "♥ " if index < current_health else "♡ "
	health_label.text = "VITALITY  " + hearts.strip_edges()

func _on_player_died() -> void:
	result_label.text = "FALLEN IN THE ASHEN GROUNDS\nWAVE %02d   /   %03d KILLS\nPRESS R TO RISE AGAIN" % [wave, kills]
	status_label.text = "THE ASHEN GROUNDS CLAIM ANOTHER SOUL"
